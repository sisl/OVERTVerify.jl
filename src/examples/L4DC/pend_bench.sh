#!/bin/bash

#SBATCH --time=00:00:1200
#SBATCH --qos=normal
#SBATCH --cpus-per-task=2
#SBATCH --mem=32G
#SBATCH --partition=quad
#SBATCH --chdir /barrett/scratch/akinwande/OVERTVerify.jl/src/examples/L4DC/
#SBATCH --job-name=l4dc_Bench
#SBATCH --error=/barrett/scratch/akinwande/OVERTVerify.jl/src/examples/L4DC/error_log/error-%j.log
#SBATCH --output=/barrett/scratch/akinwande/OVERTVerify.jl/src/examples/L4DC/output_log/output-%j.log

julia --startup-file=no --project=/barrett/scratch/akinwande/OVERTVerify.jl/Project.toml single_pend_reach.jl
