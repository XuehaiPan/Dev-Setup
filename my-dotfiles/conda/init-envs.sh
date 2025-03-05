#!/usr/bin/env bash

while read -r env CONDA_PREFIX; do
	echo "${env} ${CONDA_PREFIX}"

	mkdir -p "${CONDA_PREFIX}/etc/conda/activate.d"
	mkdir -p "${CONDA_PREFIX}/etc/conda/deactivate.d"

	if [[ ! -f "${CONDA_PREFIX}/etc/conda/activate.d/env-vars.sh" ]]; then
		# Create hook script on conda activate
		cat >"${CONDA_PREFIX}/etc/conda/activate.d/env-vars.sh" <<'EOS'
#!/usr/bin/env bash

export CONDA_C_INCLUDE_PATH_BACKUP="${C_INCLUDE_PATH}"
export CONDA_CPLUS_INCLUDE_PATH_BACKUP="${CPLUS_INCLUDE_PATH}"
export CONDA_LIBRARY_PATH_BACKUP="${LIBRARY_PATH}"
export CONDA_LD_LIBRARY_PATH_BACKUP="${LD_LIBRARY_PATH}"
export CONDA_CMAKE_PREFIX_PATH_BACKUP="${CMAKE_PREFIX_PATH}"
export CONDA_PKG_CONFIG_PATH_BACKUP="${PKG_CONFIG_PATH}"
export CONDA_CUDA_HOME_BACKUP="${CUDA_HOME}"

export C_INCLUDE_PATH="${CONDA_PREFIX}/include${C_INCLUDE_PATH:+:"${C_INCLUDE_PATH}"}"
export CPLUS_INCLUDE_PATH="${CONDA_PREFIX}/include${CPLUS_INCLUDE_PATH:+:"${CPLUS_INCLUDE_PATH}"}"
export LIBRARY_PATH="${CONDA_PREFIX}/lib${LIBRARY_PATH:+:"${LIBRARY_PATH}"}"
export LD_LIBRARY_PATH="${CONDA_PREFIX}/lib${LD_LIBRARY_PATH:+:"${LD_LIBRARY_PATH}"}"
export CMAKE_PREFIX_PATH="${CONDA_PREFIX}${CMAKE_PREFIX_PATH:+:"${CMAKE_PREFIX_PATH}"}"
if [[ -d "${CONDA_PREFIX}/lib/pkgconfig" ]]; then
	export PKG_CONFIG_PATH="${CONDA_PREFIX}/lib/pkgconfig${PKG_CONFIG_PATH:+:"${PKG_CONFIG_PATH}"}"
fi
if [[ -x "${CONDA_PREFIX}/bin/nvcc" || -f "${CONDA_PREFIX}/lib/libcudart.so" ]]; then
	export CUDA_HOME="${CONDA_PREFIX}"
fi
EOS
	fi

	if [[ ! -f "${CONDA_PREFIX}/etc/conda/deactivate.d/env-vars.sh" ]]; then
		# Create hook script on conda deactivate
		cat >"${CONDA_PREFIX}/etc/conda/deactivate.d/env-vars.sh" <<'EOS'
#!/usr/bin/env bash

export C_INCLUDE_PATH="${CONDA_C_INCLUDE_PATH_BACKUP}"
export CPLUS_INCLUDE_PATH="${CONDA_CPLUS_INCLUDE_PATH_BACKUP}"
export LIBRARY_PATH="${CONDA_LIBRARY_PATH_BACKUP}"
export LD_LIBRARY_PATH="${CONDA_LD_LIBRARY_PATH_BACKUP}"
export CMAKE_PREFIX_PATH="${CONDA_CMAKE_PREFIX_PATH_BACKUP}"
export PKG_CONFIG_PATH="${CONDA_PKG_CONFIG_PATH_BACKUP}"
export CUDA_HOME="${CONDA_CUDA_HOME_BACKUP}"

unset CONDA_C_INCLUDE_PATH_BACKUP
unset CONDA_CPLUS_INCLUDE_PATH_BACKUP
unset CONDA_LIBRARY_PATH_BACKUP
unset CONDA_LD_LIBRARY_PATH_BACKUP
unset CONDA_CMAKE_PREFIX_PATH_BACKUP
unset CONDA_PKG_CONFIG_PATH_BACKUP
unset CONDA_CUDA_HOME_BACKUP

[[ -z "${C_INCLUDE_PATH}" ]] && unset C_INCLUDE_PATH
[[ -z "${CPLUS_INCLUDE_PATH}" ]] && unset CPLUS_INCLUDE_PATH
[[ -z "${LIBRARY_PATH}" ]] && unset LIBRARY_PATH
[[ -z "${LD_LIBRARY_PATH}" ]] && unset LD_LIBRARY_PATH
[[ -z "${CMAKE_PREFIX_PATH}" ]] && unset CMAKE_PREFIX_PATH
[[ -z "${PKG_CONFIG_PATH}" ]] && unset PKG_CONFIG_PATH
[[ -z "${CUDA_HOME}" ]] && unset CUDA_HOME
EOS
	fi

	# Exit for non-Python environment
	[[ -x "${CONDA_PREFIX}/bin/python" ]] || continue

	# Create usercustomize.py in USER_SITE directory
	USER_SITE="$("${CONDA_PREFIX}/bin/python" -c 'from __future__ import print_function; import site; print(site.getusersitepackages())')"
	mkdir -p "${USER_SITE}"
	if [[ ! -s "${USER_SITE}/usercustomize.py" ]]; then
		touch "${USER_SITE}/usercustomize.py"
	fi
	if ! grep -qE '^\s*(import|from)\s+rich' "${USER_SITE}/usercustomize.py"; then
		[[ -s "${USER_SITE}/usercustomize.py" ]] && echo >>"${USER_SITE}/usercustomize.py"
		cat >>"${USER_SITE}/usercustomize.py" <<'EOS'
try:
    import rich.pretty
    import rich.traceback
except ImportError:
    pass
else:
    rich.pretty.install(indent_guides=True)
    rich.traceback.install(indent_guides=True, width=None, show_locals=True)
	del rich
EOS
	fi

done < <(conda info --envs | awk 'NF > 0 && $0 !~ /^#.*/ { printf("%s %s\n", $1, $NF) }')
