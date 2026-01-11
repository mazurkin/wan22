SHELL := /bin/bash
ROOT  := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

CONDA_ENV_NAME  = wan22

# remote host and path for rsync
RSYNC_HOST     ?= pp-wan22
RSYNC_PATH     ?= projects/wan22

# -----------------------------------------------------------------------------
# conda environment
# -----------------------------------------------------------------------------

.DEFAULT_GOAL = env-shell

.PHONY: env-init-conda
env-init-conda:
	@conda create --yes --copy --name "$(CONDA_ENV_NAME)" \
		conda-forge::python=3.12.12 \
		nvidia::cuda-toolkit=12.4.1 \
		conda-forge::glib=2.48 \
		conda-forge::cudnn=9.3.0.75 \
		conda-forge::poetry=2.2.1

.PHONY: env-init-poetry
env-init-poetry:
	@conda run --no-capture-output --live-stream --name "$(CONDA_ENV_NAME)" \
		poetry install --no-root --no-directory

.PHONY: env-init-attn
env-init-attn:
	@conda run --no-capture-output --live-stream --name "$(CONDA_ENV_NAME)" --cwd "$(ROOT)/wan22" \
		pip install flash-attn==2.7.3 --no-build-isolation

.PHONY: env-init-wan22
env-init-wan22:
	@conda run --no-capture-output --live-stream --name "$(CONDA_ENV_NAME)" --cwd "$(ROOT)/wan22" \
		pip install -r requirements.txt

.PHONY: env-update
env-update:
	@conda run --no-capture-output --live-stream --name $(CONDA_ENV_NAME) \
		poetry update

.PHONY: env-shell
env-shell:
	@conda run --no-capture-output --live-stream --name "$(CONDA_ENV_NAME)" --cwd "$(ROOT)/wan22" \
		bash

.PHONY: env-info
env-info:
	@conda run --no-capture-output --live-stream --name "$(CONDA_ENV_NAME)" \
		conda info

.PHONY: env-remove
env-remove:
	@conda env remove --yes --name "$(CONDA_ENV_NAME)"

# -----------------------------------------------------------------------------
# download
# -----------------------------------------------------------------------------

.PHONY: download-wan22
download-wan22:
	@conda run --no-capture-output --live-stream --name "$(CONDA_ENV_NAME)" \
		hf download "Wan-AI/Wan2.2-I2V-A14B" --local-dir "$(ROOT)/models/Wan2.2-I2V-A14B"
	@conda run --no-capture-output --live-stream --name "$(CONDA_ENV_NAME)" \
		hf download "Wan-AI/Wan2.2-T2V-A14B" --local-dir "$(ROOT)/models/Wan2.2-T2V-A14B"

# -----------------------------------------------------------------------------
# example
# -----------------------------------------------------------------------------

.PHONY: example
example:
	@conda run --no-capture-output --live-stream --name "$(CONDA_ENV_NAME)" --cwd "$(ROOT)/wan22" \
		python generate.py \
		 	--ckpt_dir "$(ROOT)/models/Wan2.2-T2V-A14B" \
		 	--offload_model True \
		 	--convert_model_dtype \
		 	--size 1280*720 \
		 	--task t2v-A14B \
		 	--prompt "Two anthropomorphic cats in comfy boxing gear and bright gloves fight intensely on a spotlighted stage."

# -----------------------------------------------------------------------------
# rsync
# -----------------------------------------------------------------------------

.PHONY: rsync-push
rsync-push:
	@rsync -avz \
		--exclude='/.git' \
		--exclude='/.idea' \
		--exclude='/cache/*' \
		--exclude='/target/*' \
		--exclude='/models/*' \
		--exclude='*.log' \
		--exclude='.ipynb_checkpoints' \
		'$(ROOT)/' \
		'$(RSYNC_HOST):$(RSYNC_PATH)'

.PHONY: rsync-pull
rsync-pull:
	@rsync -avz \
		--exclude='/.git' \
		--exclude='/.idea' \
		--exclude='/cache/*' \
		--exclude='/target/*' \
		--exclude='/models/*' \
		--exclude='*.log' \
		--exclude='.ipynb_checkpoints' \
		'$(RSYNC_HOST):$(RSYNC_PATH)' \
		'$(ROOT)/'

# -----------------------------------------------------------------------------
# browsing
# -----------------------------------------------------------------------------

.PHONY: browse
browse:
	@conda run --no-capture-output --live-stream --name "$(CONDA_ENV_NAME)" \
		python3 -m http.server --bind "0.0.0.0" "18181"
