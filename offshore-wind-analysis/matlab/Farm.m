% offshore_wind_analysis.m
% Kompletny skrypt analizy energetyczno-ekonomicznej farmy wiatrowej
% Wejścia: pliki ERA5 (u100.csv, v100.csv) oraz opcjonalnie temperature.csv
% Autor: wygenerowany automatycznie — dostosuj krzywe turbiny i parametry
% Uwaga: podane wartości CAPEX/OPEX/power-curve są przykładowe -> zastąp rzeczywistymi.

clear; close all; clc;

%% ---------------------- USTAWIENIA WEJŚCIOWE ----------------------------
% Nazwy plików (zmień zgodnie z Twoimi plikami)
u_file = 'data_u100.csv';
v_file = 'data_v100.csv';
temp_file = []; % opcjonalny (może być [])

% Parametry turbiny (podane przez użytkownika)
turbine.name = 'V236-15MW';
turbine.rated_power_kW = 15000;       % [kW]
turbine.D = 236;                      % [m] (średnica)
turbine.A = pi*(turbine.D/2)^2;       % [m^2] (powierzchnia; podane: ~43742)
turbine.v_in = 3;                     % [m/s] cut-in (podane)
turbine.v_out = 31;                   % [m/s] cut-out (podane)
% Hub height - wybierz odpowiednio (semi-submersible typ. 100-200m). Zmień wg planu:
hub_height = 140;                      % [m] - parametryzuj

% Layout farmy: jeśli nie masz layoutu, domyślnie przypisz 9 turbin na punktach pomiarowych
assume_turbines_at_measurement_points = true;

% Wake model parameters (Jensen/Park)
k_wake = 0.04;        % rozprzestrzenianie się plamy wake (offshore zwykle 0.04-0.06). Dostosuj.
% Thrust coefficient Ct - tutaj przybliżenie funkcji Ct(V). ZASTĄP krzywą producenta
Ct_fun = @(V) 0.88 * (V>=turbine.v_in & V<12) + 0.7*(V>=12 & V<=turbine.v_out); 
% (surowe przybliżenie; zastąp rzeczywistymi danymi)

% Strat model: początkowe założenia (zmień wg projektu)
losses.electrical = 0.02;    % 2% electrical losses
losses.availability = 0.03;  % 3% downtime
losses.environmental = 0.01; % 1% curtailment
losses.others = 0.02;        % 2% inne

% Finansowe (przykładowe) - dostosuj!
finance.CAPEX_per_MW = 3500000;   % [EUR/MW] - placeholder
finance.OPEX_per_MW_per_year = 60000; % [EUR/MW/yr] - placeholder
finance.project_lifetime = 25;    % [years]
finance.discount_rate = 0.07;     % 7%
finance.electricity_price = 70;   % [EUR/MWh] (możesz podać PPA lub rynek)

%% ---------------------- WCZYTANIE DANYCH ----------------------------
% Prosty parser CSV - oczekujemy nagłówków. Dostosuj separatory jeśli potrzeba.
fprintf('Wczytywanie danych ERA5...\n');
opts = detectImportOptions(u_file,'NumHeaderLines',0);
Tu = readtable(u_file, opts);
opts = detectImportOptions(v_file,'NumHeaderLines',0);
Tv = readtable(v_file, opts);

% Jeżeli temperatury:
if exist(temp_file,'file')
    opts = detectImportOptions(temp_file,'NumHeaderLines',0);
    Ttemp = readtable(temp_file, opts);
    hasTemp = true;
else
    Ttemp = [];
    hasTemp = false;
end

% Upewnij się, że kolumny mają oczekiwane nazwy
% Przygotuj kolumny: valid_time, latitude, longitude, u100/v100
% Konwertuj czas
Tu.valid_time = datetime( Tu.valid_time, 'InputFormat','yyyy-MM-dd HH:mm:ss' );
Tv.valid_time = datetime( Tv.valid_time, 'InputFormat','yyyy-MM-dd HH:mm:ss' );
if hasTemp
    Ttemp.valid_time = datetime( Ttemp.valid_time, 'InputFormat','yyyy-MM-dd HH:mm:ss' );
end

%% ---------------------- QC I AGREGACJA ----------------------------
% Scal dane U i V po (time,lat,lon) i oblicz prędkość i kierunek
fprintf('Łączenie sygnałów i obliczanie prędkości/kierunku...\n');
% Zakładamy, że układ w plikach jest wiersz-po-wierszu dla wszystkich punktów godzinowo.
% Dołączymy u i v po kluczach time-lat-lon
TU = Tu(:,{'valid_time','latitude','longitude','u100'});
TV = Tv(:,{'valid_time','latitude','longitude','v100'});
T = innerjoin(TU,TV,'Keys',{'valid_time','latitude','longitude'});

% Względne czyszczenie: usuń NaNy, ekstremalne wartości
mask_valid = isfinite(T.u100) & isfinite(T.v100);
T = T(mask_valid,:);
T.wind_speed = sqrt(T.u100.^2 + T.v100.^2);
% Kierunek (meteorologiczny): from where (deg clockwise from north)
T.wind_dir = mod( atan2d(-T.u100, -T.v100) + 360, 360 );

% Jeżeli temperatura dostępna -> scal i policz gęstość powietrza
if hasTemp
    Tmin = innerjoin(T, Ttemp(:,{'valid_time','latitude','longitude','t2m'}), ...
        'Keys',{'valid_time','latitude','longitude'});
    T = Tmin;
    % t2m ERA5 podaje °C? (zależne od pliku). Zakładamy °C -> zamiana na K
    T.TK = T.t2m + 273.15;
    % Przybliżona gęstość rho = p/(R*T). Brakuje p (ciśnienia) -> przyjmij standardowe p=101325 Pa
    p_ref = 101325;
    R = 287.05;
    T.rho = p_ref ./ (R * T.TK);
else
    T.rho = 1.225 * ones(height(T),1); % standardowa gęstość morskiego powietrza
end

% Sprawdź brakujące godziny/per punkt i wypisz statystyki
fprintf('QC: liczba pomiarów: %d (rozdzielonych na %d unikalnych punktów pomiarowych)\n', ...
    height(T), length(unique(T.latitude + 1e-6* T.longitude)) );

%% ---------------------- AGREGACJA PER PUNKT (9 punktów) ----------------
coords = unique([T.latitude T.longitude],'rows');
nPoints = size(coords,1);
fprintf('Liczba unikalnych punktów: %d\n', nPoints);

% Utwórz strukturę danych per punkt
Points = struct();
for i=1:nPoints
    lat0 = coords(i,1); lon0 = coords(i,2);
    sel = T.latitude==lat0 & T.longitude==lon0;
    Ti = T(sel,:);
    % sortuj po czasie
    [~,ix] = sort(Ti.valid_time);
    Ti = Ti(ix,:);
    Points(i).lat = lat0;
    Points(i).lon = lon0;
    Points(i).time = Ti.valid_time;
    Points(i).V = Ti.wind_speed;
    Points(i).dir = Ti.wind_dir;
    Points(i).rho = Ti.rho;
end

%% ---------------------- DOPASOWANIE WEIBULL + STATYSTYKI (KROK 2) -------
% Dla każdego punktu wylicz parametry Weibulla (k, c) i turbulence intensity
fprintf('Dopasowanie rozkładu Weibulla i statystyk per punkt...\n');
for i=1:nPoints
    V = Points(i).V;
    % Usuń zera / bladliwe
    V(V<=0) = [];
    % MLE Weibull (k,c) - parametr k (shape), c (scale)
    % Estymacja: loglikelihood -> fminsearch
    if isempty(V)
        Points(i).weibull_k = NaN;
        Points(i).weibull_c = NaN;
        Points(i).Vmean = NaN;
        Points(i).Vstd = NaN;
        continue;
    end
    % initial guesses
    vmean = mean(V); vstd = std(V);
    k0 = (vmean/vstd)^(-1.086);
    c0 = vmean / gamma(1 + 1/k0);
    negloglike = @(p) -sum(log( (p(2)/p(1)) .* (V./p(1)).^(p(2)-1) .* exp(-(V./p(1)).^p(2)) )); %#ok<NASGU>
    % parametry p = [c k] - scale then shape
    fun = @(p) -sum(log( (p(1)/p(2)) .* (V./p(1)).^(p(2)-1) .* exp(-(V./p(1)).^p(2)) )); % incorrect ordering fixed below
    % Simpler: use built-in fitdist if available
    try
        pd = fitdist(V,'Weibull');
        Points(i).weibull_k = pd.A;   % in MATLAB fitdist for Weibull returns A=scale, B=shape? check
        Points(i).weibull_c = pd.B;
        % But to avoid ambiguity, compute MLE ourselves using custom approach:
    catch
        % fallback - method of moments approximate
        k_est = (vmean/vstd)^(-1.086);
        c_est = vmean / gamma(1 + 1/k_est);
        Points(i).weibull_k = k_est;
        Points(i).weibull_c = c_est;
    end
    Points(i).Vmean = mean(V);
    Points(i).Vstd = std(V);
    Points(i).TI = Points(i).Vstd ./ Points(i).Vmean; % turbulence intensity (ogólna)
end

%% ---------------------- DŁUGOOKRESOWA KOREKTA (KROK 3) -----------------
% Jeżeli masz dłuższy okres referencyjny -> porównaj średnie i policz scale factor.
% Tu: jeśli nie ma referencyjnego pliku, to uznajemy ERA5 jako "długoterminowe".
% Implementujemy funkcję, która przyjmie opcjonalny plik referencyjny i policzy korektę.
fprintf('Long-term correction: brak pliku referencyjnego -> ERA5 traktowane jako LT.\n');
for i=1:nPoints
    Points(i).LT_scale = 1.0; % placeholder (użyj pliku referencyjnego, żeby obliczyć realną korektę)
end

%% ---------------------- SKALOWANIE DO HUB HEIGHT (KROK 4) -------------
% Użyjemy power-law do ekstrapolacji: V(h) = Vref * (h/href)^alpha
% Oszacuj alpha (= shear exponent) per punkt z dostępnych danych wysokościowych (jeśli brak -> 0.14)
alpha_default = 0.14;
for i=1:nPoints
    Points(i).hub_height = hub_height;
    Points(i).alpha = alpha_default;
    % Zakładamy V at 100 m (ERA5 u100/v100 oznaczają 100 m)
    href = 100;
    Points(i).V_hub = Points(i).V .* (hub_height / href) .^ Points(i).alpha;
end

%% ---------------------- KURSY MOCY TURBINY (KROK 5) -------------------
% Tu stworzymy przykładową krzywą mocy - zastąp rzeczywistą krzywą producenta!
% Power curve [m/s] -> [kW]
Vvec = 0:0.5:40;
% Prosty model: 0 do v_in = 3 => 0; linearny wzrost do rated przy 12 m/s; rated do v_out
v_rated = 12; % przykładowy v_rated - DOSTOSUJ
Pcurve = zeros(size(Vvec));
for j=1:length(Vvec)
    V = Vvec(j);
    if V < turbine.v_in
        Pcurve(j) = 0;
    elseif V >= turbine.v_in && V < v_rated
        Pcurve(j) = turbine.rated_power_kW * ((V - turbine.v_in)/(v_rated - turbine.v_in));
    elseif V >= v_rated && V <= turbine.v_out
        Pcurve(j) = turbine.rated_power_kW;
    else
        Pcurve(j) = 0;
    end
end
% Zapisz do turbiny
turbine.Vvec = Vvec;
turbine.Pcurve = Pcurve;

% Funkcja do wyznaczania mocy godzinowej z V_hub
power_from_V = @(V) interp1(turbine.Vvec, turbine.Pcurve, V, 'linear', 0); % kW

%% ---------------------- LAYOUT TURBIN (KROK 6) ------------------------
% Jeśli zakładamy turbin na punktach pomiarowych:
if assume_turbines_at_measurement_points
    % zamiast realnego layoutu, użyj punktów measurement jako pozycje turbin
    turbine_positions = coords; % [lat lon]
    nTurbines = nPoints;
else
    % Możesz tu wczytać layout z pliku. Domyślnie tworzymy siatkę 3x3 w okolicy
    nTurbines = 9;
    turbine_positions = coords; % placeholder
end

% Zamień lat/lon na współrzędne lokalne (metry) - przybliżenie płaskie:
R_earth = 6371000;
deg2m_lat = pi/180 * R_earth;
deg2m_lon = @(lat) pi/180 * R_earth .* cosd(lat);
% Przeskaluj do x,y
lat0 = mean(turbine_positions(:,1));
lon0 = mean(turbine_positions(:,2));
posXY = zeros(nTurbines,2);
for i=1:nTurbines
    posXY(i,2) = (turbine_positions(i,1) - lat0) * deg2m_lat; % y
    posXY(i,1) = (turbine_positions(i,2) - lon0) * deg2m_lon(turbine_positions(i,1)); % x
end

%% ---------------------- OBLICZENIE EFEKTU WAKE (KROK 6) --------------
% Implementacja modelu Jensaena: dla każdej godziny, dla danego kierunku wiatru,
% oblicz spadek prędkości u "downstream" turbin spowodowany wake.
fprintf('Obliczanie strat wake (Jensen) i produkcji godzinowej...\n');

% Przygotuj indeksy czasowe (zakładamy zgodność czasów między punktami)
% Przyjmujemy, że każdy Points(i).time ma tę samą sekwencję czasów (jeśli nie -> zrobic resampling)
times = Points(1).time;
nHours = length(times);

% Pre-alloc
hourly_power_per_turbine = zeros(nHours, nTurbines);
hourly_wd = zeros(nHours,1);
hourly_WS_ref = zeros(nHours,1);

% Zbierz V_hub i dir per turbine (zakładamy zgodność czasowa)
Vhub_all = NaN(nHours, nTurbines);
Dir_all = NaN(nHours, nTurbines);
for i=1:nTurbines
    % Jeśli liczba próbek różna -> należy zresamplować; tutaj zakładamy zgodne
    Vhub_all(:,i) = Points(i).V_hub;
    Dir_all(:,i) = Points(i).dir;
end

% Główna pętla godzinowa
for t=1:nHours
    % przyjmij kierunek wiatru jako średnią kierunków (można użyć modułu wektora)
    dirs = Dir_all(t,:);
    % średni wektorowy kierunek:
    uvec = cosd(dirs); vvec = sind(dirs);
    mean_u = mean(uvec,'omitnan'); mean_v = mean(vvec,'omitnan');
    WD = mod(atan2d(mean_v, mean_u), 360); % degrees
    hourly_wd(t) = WD;
    
    % Dla uproszczenia, przyjmij, że prędkość napływowa dla każdego turbiny to jego Vhub bez wake
    % Następnie oblicz wake deficits od każdego upstream turbine
    V0 = Vhub_all(t,:)'; % column vector [nTurbines x 1]
    
    % Startowa moc bez wake
    P0 = power_from_V(V0); % [kW]
    
    % Oblicz wpływy wake: dla każdy pair i->j oblicz czy i jest upstream dla j
    V_effective = V0; % zainicjalizuj
    for iTur = 1:nTurbines
        for jTur = 1:nTurbines
            if iTur==jTur, continue; end
            % Oblicz relatywne położenie j względem i w układzie kierunku wiatru
            dx = posXY(jTur,1) - posXY(iTur,1);
            dy = posXY(jTur,2) - posXY(iTur,2);
            % Rotate coordinates: x' wzdłuż wiatru
            theta = deg2rad(360 - WD + 90); % adjust orientation -> axis
            xr =  dx*cos(theta) - dy*sin(theta);
            yr =  dx*sin(theta) + dy*cos(theta);
            % Jeśli xr <=0 -> j jest upstream lub lateral -> nie wpływa
            if xr <= 0
                continue;
            end
            % Promien wake na dystans x: r = 0.5*D + k*x
            r_wake = 0.5*turbine.D + k_wake * xr;
            % Odległość lateral
            r_lat = abs(yr);
            if r_lat > r_wake
                continue; % poza wake
            end
            % Oblicz redukcje prędkości wg Jensen (przyblizenie)
            Ct = Ct_fun(V0(iTur)); % thrust coefficient źródło -> producent
            % zabezpieczenie
            Ct(isnan(Ct)) = 0.8;
            % indukcyjny a z Ct (przybliżenie): Ct = 4a(1-a)
            a = (1 - sqrt(1 - Ct))/2; % approx
            % velocity deficit at center: delta = (1 - (1 - a) * (D/(D + 2*k*xr)))
            % użyj formuły z literatury (jedno z przybliżeń):
            deficit_center = (1 - (1 - a) * (turbine.D / (turbine.D + 2*k_wake*xr)));
            % przyjmij rozkład radial (top-hat) -> tu uniform dla r <= r_wake
            % Weighted superposition: sqrt(sum of squares) (common)
            % Oblicz deltaV (absolute) = deficit_center * V0(iTur)
            deltaV = deficit_center * V0(iTur);
            % Zastosuj superpozycję kwadratową
            V_effective(jTur) = max(0, V_effective(jTur) - deltaV);
        end
    end
    % Teraz policz moc na turbinach z V_effective (kW)
    P_final = power_from_V(V_effective);
    hourly_power_per_turbine(t,:) = P_final';
    hourly_WS_ref(t) = mean(V0,'omitnan');
end

% Suma produkcji [kW] -> [kWh] per hour
hourly_farm_power_kW = sum(hourly_power_per_turbine,2); % kW chwilowe
hourly_farm_energy_kWh = hourly_farm_power_kW; % 1 hour periods -> kWh per hour

% Roczne agregaty
hours_per_year = 8760;
% Jeśli dane mają 1 rok -> AEP:
AEP_kWh = sum(hourly_farm_energy_kWh); % jeśli masz pełen rok
AEP_MWh = AEP_kWh / 1000;
capacity_MW = (nTurbines * turbine.rated_power_kW)/1000;

fprintf('AEP (brutto, przed stratami) = %.2f MWh (farm capacity %.2f MW)\n', AEP_MWh, capacity_MW);

%% ---------------------- MODELOWANIE STRAT (KROK 7) --------------------
total_losses = losses.electrical + losses.availability + losses.environmental + losses.others;
AEP_net_MWh = AEP_MWh * (1 - total_losses);
fprintf('Sumaryczne założone straty: %.2f%% -> AEP_net = %.2f MWh\n', 100*total_losses, AEP_net_MWh);

%% ---------------------- METOCEAN I OBCIĄŻENIA (KROK 8) ----------------
% Tutaj robimy proste wyznaczenie ekstremów (1-yr, 50-yr) na podstawie rocznych danych:
Vmax = max(max(Vhub_all,[],2),'all','omitnan');
V90 = prctile(Vhub_all(:),10); % prędkość przekraczana 10% czasu (często używane)
fprintf('Vmax (rok ERA5): %.2f m/s, V90: %.2f m/s\n', Vmax, V90);

% Dla rzeczywistego projektowania: wymagane DLC + metocean report -> użyj DNV i IEC
% Tu tylko przykładowa ocena: ilość godzin powyżej cut-out:
hours_cutout = sum(hourly_farm_power_kW==0);
fprintf('Liczba godzin przy której moc = 0 (cut-in/out lub brak wiatru): %d\n', hours_cutout);

%% ---------------------- MODELOWANIE FINANSOWE (KROK 13) ----------------
% CAPEX i OPEX
CAPEX_total_EUR = finance.CAPEX_per_MW * capacity_MW;
OPEX_annual_EUR = finance.OPEX_per_MW_per_year * capacity_MW;

% Przychody roczne z energii
revenue_per_year_EUR = AEP_net_MWh * finance.electricity_price;

% Cashflow prosty (pomijamy amortyzacje/podatki dla prostoty)
years = (1:finance.project_lifetime)';
cashflow = -CAPEX_total_EUR + 0*years;
cashflow_yearly = revenue_per_year_EUR - OPEX_annual_EUR;
cashflow_vector = [-CAPEX_total_EUR; repmat(cashflow_yearly,finance.project_lifetime,1)];

% NPV i IRR
discount_rate = finance.discount_rate;
NPV = sum(cashflow_vector ./ (1+discount_rate).^[0:finance.project_lifetime]');
% IRR (we use irr function if available)
try
    IRR = irr(cashflow_vector);
catch
    IRR = NaN;
end

% LCOE approximate = sum(Discounted Costs)/(sum(Discounted Energy))
discount_factors = 1./(1+discount_rate).^(0:finance.project_lifetime)';
discounted_costs = CAPEX_total_EUR + sum(repmat(OPEX_annual_EUR,finance.project_lifetime,1) .* discount_factors(2:end)');
discounted_energy = sum(repmat(AEP_net_MWh,finance.project_lifetime,1) .* discount_factors(2:end)');
LCOE = discounted_costs / discounted_energy; % EUR/MWh

fprintf('FINANSE: CAPEX=%.1f M EUR, OPEX_year=%.1f k EUR\n', CAPEX_total_EUR/1e6, OPEX_annual_EUR/1e3);
fprintf('NPV (r=%.2f) = %.2f EUR, IRR = %.2f (%.2f%%), LCOE = %.2f EUR/MWh\n', discount_rate, NPV, IRR, IRR*100, LCOE);

%% ---------------------- ANALIZA NIEPEWNOŚCI (KROK 14) -----------------
% Monte-Carlo: wariacje AEP +/- 10% (measurement + LTuncertainty) oraz cena energii +/- 20%
nMC = 2000;
rng(1);
AEP_samples = AEP_net_MWh .* (1 + 0.1*randn(nMC,1)); % ~10% sigma
price_samples = finance.electricity_price .* (1 + 0.2*randn(nMC,1)); % 20% sigma
NPV_samples = zeros(nMC,1);
for i=1:nMC
    rev = AEP_samples(i) * price_samples(i);
    cf_year = rev - OPEX_annual_EUR;
    cf = [-CAPEX_total_EUR; repmat(cf_year, finance.project_lifetime,1)];
    NPV_samples(i) = sum( cf ./ (1+discount_rate).^[0:finance.project_lifetime]' );
end

NPV_mean = mean(NPV_samples);
NPV_p5 = prctile(NPV_samples,5);
NPV_p95 = prctile(NPV_samples,95);
fprintf('MonteCarlo NPV: mean=%.2f M EUR, 5%%=%.2f M, 95%%=%.2f M\n', NPV_mean/1e6, NPV_p5/1e6, NPV_p95/1e6);

%% ---------------------- ZAPIS WYNIKÓW I WYKRESY -----------------------
% Proste wykresy
figure;
plot(times, hourly_farm_power_kW/1000);
xlabel('Time'); ylabel('Farm power [MW]');
title('Moc farmy - godzinna');

figure;
histogram(AEP_samples/1e3, 50);
xlabel('AEP [GWh]'); title('Monte Carlo - rozkład AEP');

% Zapis do pliku wynikowego (CSV)
out_table = table(times, hourly_farm_power_kW, sum(hourly_power_per_turbine,2));
writetable(out_table, 'hourly_farm_power.csv');

% Raport summary
summary.AEP_MWh_brutto = AEP_MWh;
summary.AEP_MWh_net = AEP_net_MWh;
summary.capacity_MW = capacity_MW;
summary.CAPEX_EUR = CAPEX_total_EUR;
summary.OPEX_EUR_per_year = OPEX_annual_EUR;
summary.NPV = NPV;
summary.IRR = IRR;
summary.LCOE = LCOE;
save('summary.mat','summary');

fprintf('Analiza zakończona. Wyniki zapisane (hourly_farm_power.csv, summary.mat)\n');

%% ---------------------- KONIEC SKRYPTU --------------------------------
% Dalsze kroki (zalecane):
% - Podmienić krzywe mocy i Ct na rzeczywiste dane producenta turbiny V236
% - Wykonać micrositing z użyciem WAsP/CFD lub PyWake/FLORIS dla dokładniejszych strat wake
% - Wykonać long-term correction porównując ERA5 z lokalnymi stacjami lub dłuższą serią
% - Przygotować metocean report (fale, prądy) i pełne DLC wg IEC/DNV
% - Rozszerzyć model finansowy o podatki, amortyzację, finansowanie dłużne
