import xarray as xr
import pandas as pd
import numpy as np
import os

def nc_to_csv_efficient(nc_file_path, output_dir=None, method='sample', **kwargs):
    """
    Convert large NetCDF file to CSV format efficiently
    
    Args:
        nc_file_path (str): Path to the NetCDF file
        output_dir (str): Directory for output files
        method (str): Conversion method - 'sample', 'subset', 'chunked', or 'variable_split'
        **kwargs: Additional parameters for each method
    """
    
    try:
        # Load the NetCDF file
        print(f"Loading NetCDF file: {nc_file_path}")
        ds = xr.open_dataset(nc_file_path)
        
        # Print dataset information
        print(f"\nDataset information:")
        print(f"Dimensions: {dict(ds.sizes)}")
        print(f"Variables: {list(ds.data_vars.keys())}")
        print(f"Coordinates: {list(ds.coords.keys())}")
        print(f"Total data points: {np.prod(list(ds.sizes.values()))}")
        
        # Set output directory
        if output_dir is None:
            output_dir = os.path.dirname(nc_file_path)
        
        base_name = os.path.splitext(os.path.basename(nc_file_path))[0]
        
        if method == 'sample':
            return convert_sample(ds, output_dir, base_name, kwargs.get('sample_size', 10000))
        elif method == 'subset':
            return convert_subset(ds, output_dir, base_name, kwargs)
        elif method == 'chunked':
            return convert_chunked(ds, output_dir, base_name, kwargs.get('chunk_size', 100000))
        elif method == 'variable_split':
            return convert_by_variable(ds, output_dir, base_name)
        else:
            print(f"Unknown method: {method}")
            return None
            
    except Exception as e:
        print(f"Error: {str(e)}")
        return None
    finally:
        if 'ds' in locals():
            ds.close()

def convert_sample(ds, output_dir, base_name, sample_size=10000):
    """Sample random points from the dataset"""
    print(f"\nMethod: Random sampling ({sample_size} points)")
    
    # Convert to dataframe and sample
    df = ds.to_dataframe().reset_index()
    df_sample = df.sample(n=min(sample_size, len(df)), random_state=42)
    
    output_path = os.path.join(output_dir, f"{base_name}_sample_{sample_size}.csv")
    df_sample.to_csv(output_path, index=False)
    
    print(f"✓ Sample CSV saved: {output_path}")
    print(f"Sample shape: {df_sample.shape}")
    print(f"\nFirst 5 rows:")
    print(df_sample.head())
    
    return output_path

def convert_subset(ds, output_dir, base_name, params):
    """Extract a geographic/temporal subset"""
    print(f"\nMethod: Geographic/temporal subset")
    
    # Default subset parameters
    lat_range = params.get('lat_range', [40, 60])  # Example: Europe
    lon_range = params.get('lon_range', [-10, 30])
    time_slice = params.get('time_slice', slice(0, 10))  # First 10 time steps
    
    print(f"Latitude range: {lat_range}")
    print(f"Longitude range: {lon_range}")
    print(f"Time slice: {time_slice}")
    
    # Subset the data
    ds_subset = ds.sel(
        latitude=slice(lat_range[1], lat_range[0]),  # Note: latitude often decreases
        longitude=slice(lon_range[0], lon_range[1]),
        valid_time=time_slice
    )
    
    print(f"Subset dimensions: {dict(ds_subset.sizes)}")
    
    # Convert to dataframe
    df = ds_subset.to_dataframe().reset_index()
    
    output_path = os.path.join(output_dir, f"{base_name}_subset.csv")
    df.to_csv(output_path, index=False)
    
    print(f"✓ Subset CSV saved: {output_path}")
    print(f"Subset shape: {df.shape}")
    print(f"\nFirst 5 rows:")
    print(df.head())
    
    return output_path

def convert_chunked(ds, output_dir, base_name, chunk_size=100000):
    """Process data in chunks"""
    print(f"\nMethod: Chunked processing (chunk size: {chunk_size})")
    
    df = ds.to_dataframe().reset_index()
    total_rows = len(df)
    num_chunks = (total_rows // chunk_size) + 1
    
    print(f"Total rows: {total_rows}")
    print(f"Number of chunks: {num_chunks}")
    
    output_paths = []
    
    for i in range(num_chunks):
        start_idx = i * chunk_size
        end_idx = min((i + 1) * chunk_size, total_rows)
        
        if start_idx >= total_rows:
            break
            
        chunk_df = df.iloc[start_idx:end_idx]
        output_path = os.path.join(output_dir, f"{base_name}_chunk_{i+1:03d}.csv")
        chunk_df.to_csv(output_path, index=False)
        output_paths.append(output_path)
        
        print(f"✓ Chunk {i+1}/{num_chunks} saved: {output_path} ({len(chunk_df)} rows)")
    
    return output_paths

def convert_by_variable(ds, output_dir, base_name):
    """Create separate CSV files for each variable"""
    print(f"\nMethod: Split by variable")
    
    output_paths = []
    
    for var_name in ds.data_vars:
        print(f"\nProcessing variable: {var_name}")
        
        # Extract single variable with coordinates
        var_ds = ds[[var_name]]
        df = var_ds.to_dataframe().reset_index()
        
        output_path = os.path.join(output_dir, f"{base_name}_{var_name}.csv")
        df.to_csv(output_path, index=False)
        output_paths.append(output_path)
        
        print(f"✓ Variable CSV saved: {output_path}")
        print(f"Shape: {df.shape}")
        print(f"Columns: {list(df.columns)}")
    
    return output_paths

if __name__ == "__main__":
    # Your file path
    input_file = r"C:\Users\User\Downloads\temp.nc"
    output_directory = r"C:\Users\User\Downloads\aaa"
    
    print("Available conversion methods:")
    print("1. sample - Random sample of data points")
    print("2. subset - Geographic/temporal subset")
    print("3. chunked - Split into multiple CSV files")
    print("4. variable_split - Separate CSV for each variable")
    
    # Choose your method:
    
    # Option 1: Random sample (recommended for initial exploration)
    print("\n" + "="*50)
    print("Converting with random sample method...")
    nc_to_csv_efficient(input_file, output_directory, method='sample', sample_size=50000)
    
    # Option 2: Geographic subset (Europe example)
    print("\n" + "="*50)
    print("Converting with subset method...")
    nc_to_csv_efficient(input_file, output_directory, method='subset', 
                       lat_range=[45, 65], lon_range=[22, 27], time_slice=slice(0, 24))
    
    # Option 3: Split by variable (creates one CSV per variable)
    print("\n" + "="*50)
    print("Converting with variable split method...")
    nc_to_csv_efficient(input_file, output_directory, method='variable_split')