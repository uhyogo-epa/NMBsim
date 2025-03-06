# NMBsim: A Neuromuscular Blockade Simulator for TOF and PTC

## Overview
NMBsim is a MATLAB-based simulator developed from the study *"A Comprehensive Model of Neuromuscular Monitoring Measures During General Anesthesia."* 
This model incorporates the effects of Non-depolarizing Neuromuscular Blockers (NDNBs) on neuromuscular transmission and predicts neuromuscular monitoring measures such as Train-of-Four Ratio (TOFR), Train-of-Four Count (TOFC), and Post-tetanic Count (PTC).

<p align="center">
  <img src="docs/images/monitoring_measures.png" alt="Monitoring Measures" width="60%">
</p>


This repository includes:
- **MATLAB code**: Implementation of the neuromuscular transmission model
- **.mat data**: Parameter datasets of 21 patients
- **Documentation**: Model description, usage guide, and references

## Installation
Ensure MATLAB is installed before proceeding.

```sh
git clone https://github.com/uhyogo-epa/NMBsim.git
cd NMBsim
```

## Usage
### Running the Simulation
Execute the following command in MATLAB to start the simulation:
```matlab
run('src/main.m')
```

### Loading Patient Data
To load specific patient data:
```matlab
data = load('data/patient_01.mat');
```

### Visualizing Simulation Results
```matlab
visualization(simulation_results);
```

## Data
`.mat` files in the `data/` directory contain the optimized parameters for each patient. 
For more details, refer to [docs/data_description.md](docs/data_description.md).

## License
This project is licensed under the [MIT License](LICENSE).

## References
- H. Hoshino, H. Miyaguchi, E. Furutani, T. Sugawara, T. Takeda, and G. Shirakami, *"A Comprehensive Model of Neuromuscular Monitoring Measures During General Anesthesia,"* 
