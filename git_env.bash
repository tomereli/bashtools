
# *** Always prefer adding new Env settings to current file instead of ~/.bashrc ***

function echr()
{
	echo -e '\033[1;31m'"$@"'\033[0m'
}

function echb()
{
	echo -e '\033[1;34m'"$@"'\033[0m'
}


function setgit()
{
	#load git completion only if not available in the server
	complete -p | grep git &>/dev/null || {
		if [ -f ${env_dir}/git-env/git-completion.bash ]; then
			echo loading git-completion.bash
			source ${env_dir}/git-env/git-completion.bash
		fi
	}

	if [ -f ${env_dir}/git-env/git_prompt.bash ]; then
		echo loading git_prompt.bash
		source ${env_dir}/git-env/git_prompt.bash
		setps1
	else
		echo loading MYPS
		export MYPS='$(echo -n "${PWD/#$HOME/~}" | awk -F "/" '"'"'{if (length($0) > 14) { if (NF>4) print $1 "/" $2 "/.../" $(NF-1) "/" $NF;
										else if (NF>3) print $1 "/" $2 "/.../" $NF; else print $1 "/.../" $NF; } else print $0;}'"'"')'
		PS1='${YOCTO_PLATFORM}@$(__git_ps1 "(%s)")$(eval "echo ${MYPS}")\>'
	fi
}

function remove_trailing_whitespaces()
{
    sed -i 's/[ \t]*$//' "$1"
}

function config_value()
{
    local config_file="$1"
    local config_var="$2"
    local sed_command=`grep $2= $1 | sed -e 's/"//g' -e 's/'$2='//'`
    echo "$sed_command"
}

function set_ugw_aliases()
{
	local ugw_root=${1-${env_root}}
	local ugw_dir=${ugw_root}/ugw
	local dotconfig="${ugw_dir}/openwrt/core/.config"
	local arch=$(config_value "$dotconfig" CONFIG_ARCH)
	local cpu=$(config_value "$dotconfig" CONFIG_CPU_TYPE)
	local board=$(config_value "$dotconfig" CONFIG_TARGET_BOARD)
	local uclibc_version=$(config_value "$dotconfig" CONFIG_UCLIBC_VERSION)
	local build_suffix=$(config_value "$dotconfig" CONFIG_BUILD_SUFFIX)
	local target_dir_name="target-${arch}_${cpu}_uClibc-${uclibc_version}_${build_suffix}"
	local build_dir="${ugw_dir}/openwrt/core/build_dir/${target_dir_name}"
	local platform_dir="${ugw_dir}/openwrt/core/target/linux/${board}"
	local subtarget=`for dir in "$platform_dir"/*; do [[ -d "$dir" ]] && [[ -e "$dir"/target.mk ]] && [[ $(config_value "$dotconfig" "CONFIG_TARGET_${board}_$(basename $dir)") == "y" ]] && echo $(basename "$dir"); done`
	local kernel_build_dir=${build_dir}/linux-${board}$(if [ "$subtarget" != "" ]; then echo "_$subtarget"; fi)
	local linux_version=`if [ "$subtarget" == puma ]; then echo "3.12.59"; else echo "3.10.104"; fi;`
	local linux_dir="${kernel_build_dir}/linux-${linux_version}"
	local wav600=$(config_value "$dotconfig" CONFIG_PACKAGE_ltq-wlan-wave_6x)
	local wav500=$(config_value "$dotconfig" CONFIG_PACKAGE_ltq-wlan-wave_5_x)

	alias u="cd ${ugw_dir}"
	alias l="cd ${linux_dir}"
	alias c="cd ${ugw_dir}/openwrt/core"
	alias cc="cd ${ugw_dir}/config_cpe"
	alias t="cd ${ugw_dir}/target"
	alias s="cd ${ugw_dir}/../../standalone"
	alias m="cd ${ugw_dir}/../../.repo/manifests"
	alias slg="cd ${ugw_dir}/ugw_components/sl_components/sl_guest_access"
	alias slc="cd ${ugw_dir}/ugw_components/sl_components/sl_client_mode"
	alias sys="cd ${ugw_dir}/ugw_components/system_service/fapi_system/src"
	alias pp="cd ${ugw_dir}/feed_puma_components/packages/pp_drv/src"
	alias pdsp="cd ${ugw_dir}/feed_puma_components/packages/pdsp_drv/src"
	alias hil="cd ${ugw_dir}/feed_puma_components/packages/hil_drv/src"
	alias lpal="cd ${ugw_dir}/feed_puma_components/packages/puma_lpal/src"
	alias toe="cd ${ugw_dir}/feed_puma_components/packages/toe_drv/src"
	alias ppa="cd ${ugw_dir}/drivers/ppa_drv/src"
	alias qos="cd ${ugw_dir}/ugw_components/qos_service"
	alias b="cd ${build_dir}"
	alias p="cd ${platform_dir}"
	alias kp="cd ${ugw_dir}/puma_kernel_patches"
	alias k="cd ${ugw_dir}/openwrt/core/kernel_tree"
	alias out="cd ${UGW_BIN_DIR}/$board/$target/"

	# multiap aliases
	alias fmap="cd ${ugw_dir}/feed_multiap"
	alias fmapf="cd ${ugw_dir}/feed_multiap/multiap_framework"
	alias fmapc="cd ${ugw_dir}/feed_multiap/multiap_common"
	alias fbeer="cd ${ugw_dir}/feed_beerocks"

	# wlan aliases
	if [ "$wav600" == "y" ]; then
		alias fapic="cd ${ugw_dir}/ugw_components/fapi_wlan_common_6x"
		alias fapiv="cd ${ugw_dir}/ugw_components/fapi_wlan_vendor_wave_6x"
		alias slw="cd ${ugw_dir}/ugw_components/feed_sl_wlan_6x"
	elif [ "$wav500" == "y" ]; then
		alias fapic="cd ${ugw_dir}/ugw_components/fapi_wlan_common"
		alias fapiv="cd ${ugw_dir}/ugw_components/fapi_wlan_vendor_wave"
		alias slw="cd ${ugw_dir}/ugw_components/feed_sl_wlan_6x"
	fi
	alias findError='grep -rs "Error " '${ugw_dir}'/openwrt/core/logs/ | grep -v ignored'
}

function ugw_set_multiap_source_dir()
{
	local repos=(framework common controller agent)

	[ -z $map_root ] && echo "multiap SDK not found" && return 1
	[ -z $UGW_CORE_DIR ] && echo "UGW SDK not found" && return 1

	for repo in ${repos[@]}; do
        sed -i "s,# CONFIG_multiap_${repo}_USE_CUSTOM_SOURCE_DIR is not set,CONFIG_multiap_${repo}_USE_CUSTOM_SOURCE_DIR=y\nCONFIG_multiap_${repo}_CUSTOM_SOURCE_DIR=\"${map_root}/${repo}\",g" $UGW_CORE_DIR/.config
	done	
}

function set_multiap_env()
{
	export map_root=${1-${env_root}}
	echo "multiap SDK discovered!"
	alias map="cd ${map_root}"
	alias mapc="cd ${map_root}/common"
	alias mapcc="cd ${map_root}/controller"
	alias mapca="cd ${map_root}/agent"
	alias mapf="cd ${map_root}/framework"
	alias mapt="cd ${map_root}/tools"
	alias maptools="${map_root}/tools/maptools.sh"
	alias map_build_deploy_rdkb='maptools build all -f PASSIVE_MODE=ON;maptools deploy all --pack-only;chdlab copy $rdkb_root/sdk/multiap/build/pack/{deploy_rdkb.sh,multiap_deploy.tar.gz} to GW -P 5556'
}

function set_cvbuilder_env()
{
	local cvbuilder_root=${env_root}/cvbuilder
	#local ugw_root=

	dirs=($(ls -td ${cvbuilder_root}/*/))

	for dir in "${dirs[@]}"
	do
		if [ -e ${dir}/ugw_sw/.ugw_ref_states_git ]; then
			ugw_root=${dir}/ugw_sw
			break
		fi
	done

	[[ -z $ugw_root ]] && return
	echo "cvbuilder SDK discovered!"
	alias cvb="cd $cvbuilder_root"
	set_ugw_git_env $ugw_root
}

function rdkb_copy_image()
{
	local image=$1
	local tftp=${2-10.124.123.56}
	local build_dir=${rdkb_root}/atom_rdkbos/build
	[ -z "$image" ] && image=$(ls -Art ${build_dir}/tmp/deploy/images/puma7-atom/*image\.*.uimg | tail -n 1)
	echo "copy to tftp: sshpass -p libit scp $image libit@10.124.123.56:/tftpboot/localDisk/users/$USER/atom.uimg"
	sshpass -p libit scp $image libit@$tftp:/tftpboot/localDisk/users/$USER/atom.uimg
}

function set_rdkb_aliases()
{
	export sdk_dir=${rdkb_root}/sdk
	set_multiap_env ${rdkb_root}/sdk/multiap

	alias b='cd ${rdkb_root}/atom_rdkbos/build'
	alias m='cd ${rdkb_root}/atom_rdkbos/meta-rdk-soc-intel-puma7'
	alias s='cd ${sdk_dir}'
	alias dpal='cd ${rdkb_root}/sdk/wav-dpal'
	alias spal='cd ${rdkb_root}/sdk/wav-spal'
	alias metamap='cd ${rdkb_root}/atom_rdkbos/meta-rdk-soc-intel-puma7/meta-multiap'
}

function set_rdkb_env()
{
	echo "RDKB SDK discovered!"
	export rdkb_root=${env_root}/rdkb
	set_rdkb_aliases
}

function set_ugw_git_env()
{
	local __ugw_root=${1-${env_root}}
	[[ ! -e ${__ugw_root}/.ugw_ref_states_git ]] && return
	echo "UGW git SDK discovered!"

	export ugw_root=${__ugw_root}
	export ugw_sdk="ugw-git"
	export ugw_tag=$(cd ${ugw_root} && git describe --tags && cd -)
	export ugw_model="$(cat ${ugw_root}/ugw/openwrt/core/active_config | cut -d'/' -f 4 | awk '{print tolower($0)}')"
	export UGW_CORE_DIR="${ugw_root}/ugw/openwrt/core"
	if [[ $ugw_model == *"haven_park"* ]]; then
		export UGW_BIN_DIR="${ugw_root}/ugw/openwrt/core/bin/x86/$ugw_model/"
	elif [[ $ugw_model == *"grx750"* ]]; then
		export UGW_BIN_DIR="${ugw_root}/ugw/openwrt/core/bin/x86/$ugw_model/"
	else
		export UGW_BIN_DIR="${ugw_root}/ugw/openwrt/core/bin/lantiq/$ugw_model/"
	fi
	set_ugw_aliases ${ugw_root}
	echo "UGW_CORE_DIR: ${UGW_CORE_DIR}"
	echo "TAG: ${ugw_tag}"
	echo "MODEL: ${ugw_model}"
	source ${env_dir}/git-env/git_scripts.sh
}

function show_git_env()
{
	echo "SDK: ${ugw_sdk}"
	echo "TAG: ${ugw_tag}"
	echo "MODEL: ${ugw_model}"
	echo "UGW_CORE_DIR: ${UGW_CORE_DIR}"
}

function set_git_env()
{
	export env_root=`pwd -P`
	source ${env_dir}/git_env.bash
	setgit
	alias r="cd ${env_root}"
	echo "Git Env was set, trying to guess SDK..."
	
	[[ -e ${env_root}/map/.repo ]] && set_multiap_env ${env_root}/map/multiap
	[[ -e ${env_root}/rdkb/.repo ]] && set_rdkb_env && return
	[[ -e ${env_root}/cvbuilder/wlan_build.config ]] && set_cvbuilder_env && return
	[[ -e ${env_root}/ugw/ugw_sw/.ugw_ref_states_git ]] && set_ugw_git_env ${env_root}/ugw/ugw_sw/ && return
	[[ -e ${env_root}/.ugw_ref_states_git ]] && set_ugw_git_env && return
}

function repo_delete_all_branches()
{
	repo &> /dev/null || { 
		echr "not a repo envorpnment!" && return 1
	} && {
	    if [ -n "$1" ]; then echr "deleting and pruning all branches"; else echr "deleting all branches"; fi
	    repo forall -p -c 'git merge --abort; git cherry-pick --abort; git rebase --abort; git checkout .; git clean -xdf; git checkout $REPO_LREV; git branch | grep -v \* | xargs -I {} sh -c "git branch -D {}"; if [ -n "'"$1"'" ]; then echo pruning; git remote prune $REPO_REMOTE; fi'
	}
}

function repo_merge_feature_branch()
{
	[[ -z $1 ]] && echr "missing feature branch parameter" && return 1
	repo &> /dev/null || { 
		echr "not a repo envorpnment!" && return 1
	} && repo forall -p -c 'if git branch -a | grep '"$1"'; then git checkout $REPO_LREV -b merge_'"$1"'_to_$REPO_RREV && git merge $REPO_REMOTE/'"$1"' --no-edit; fi' &> /dev/null
}

function repo_checkout_feature_branch()
{
	[[ -z $1 ]] && echr "missing feature branch parameter" && return 1
	repo &> /dev/null || { 
		echr "not a repo envorpnment!" && return 1
	} && repo forall -c 'git checkout '"$1"'' &> /dev/null
}

function repo_model_suffix()
{
	[[ -n $(repo manifest | grep default | grep revision | grep 'wcci\|beerocks') ]] && echo '72' ||
	[[ -n $(repo manifest | grep default | grep revision | grep '7.4.') ]] && echo '74' || echo '73'
}

function ugw_prepare_clean()
{
	local OPTIND=1 delete=1 toolchain=1 model= branch=

	[[ "$ugw_sdk" != "ugw-git" ]] && echr "not a ugw sdk" && return 1
	
	cd ${ugw_root}/ugw/openwrt/core
	model_suffix=$(repo_model_suffix)

	while getopts hd:t:b:m: opt; do
		case $opt in
			h)
				echo "usage: ugw_prepare_clean [-h] [-m target] [-f feature_branch] [-t enable_ext_toolchain] [-d delete_local_branches]"
				echo "Prepare ugw environement- clean, prepare, switch, set external toolchain, etc"
				echo "	-h			displat this help and exit"
				echo "	-d 0/1			(default 1) delete all local branches, checkout modified files and discard untracked files prior to prepare"
				echo "	-t 0/1			(default 1) enable/disable external toolchain"
				echo "	-b feature_branch	checkout to feature branch before prepare"
				echo "	-m model		switch to selected model"
				echo "		supported models:"
				echo "			axepoint 		- GRX350_1600_MR_AXEPOINT_6X_WAV600_ETH_RT_74"
				echo "			gw/grx350 		- GRX350_1600_MR_ETH_RT_72/3/4"
				echo "			gw_map 			- GRX350_1600_MR_ETH_RT_MAP_72/3/4"
				echo "			gw_1200/grx350_1200 	- GRX350_1200_MR_ETH_RT_72/3"
				echo "			ire/ire350	 	- GRX350_1600_MR_ETH_RT_IRE_72/3"
				echo "			ire_1200/ire350_1200 	- GRX350_1200_MR_ETH_RT_IRE_72/3"
				echo "			ire220		 	- IRE220_1600_MR_ETH_RT_IRE_72/3"
				echo "			grx330		 	- GRX330_EL_ETH_RT_72/3"

				return 0
				;;
			d) [[ $OPTARG == 0 ]] && delete=0
				;;
			t) [[ $OPTARG == 0 ]] && toolchain=0
				;;
			b) branch=$OPTARG
				;;
			m) case $OPTARG in
				axepoint)
					model=./ugw/config/GRX350_1600_MR_AXEPOINT_6X_WAV600_ETH_RT_"$model_suffix"
					;;
				gw_map)
					model=./ugw/config/GRX350_1600_MR_ETH_RT_MAP_"$model_suffix"
					;;
				gw|grx350)
					model=./ugw/config/GRX350_1600_MR_ETH_RT_"$model_suffix"
					;;
				gw_1200|grx350_1200)
					model=./ugw/config/GRX350_1200_MR_ETH_RT_"$model_suffix"
					;;
				ire350)
					model=./ugw/config/GRX350_1600_MR_ETH_RT_IRE_"$model_suffix"
					;;
				ire350_1200)
					model=./ugw/config/GRX350_1200_MR_ETH_RT_IRE_"$model_suffix"
					;;
				ire)
					model=./ugw/config/IRE220_1600_MR_ETH_RT_IRE_"$model_suffix"
					;;
				grx330)
					model=./ugw/config/GRX330_EL_ETH_RT_"$model_suffix"
					;;
				*) echr "unsupported model $OPTARG, run ugw_prepare_clean -h to see help menu"; return 1
			    esac
			    ;;
			*) echr "unsupported model $OPTARG, run ugw_prepare_clean -h to see help menu"; return 1
				;;
			esac
	done

	echr "ugw_prepare_clean: model=$model, branch=$branch, use_ext_toolchain=$toolchain, delete_all_branches=$delete"
	echb "ugw_prepare_clean: (echo y;echo y) | ../../config_cpe/ugw-prepare-all.sh -o"
	(echo y;echo y) | ../../config_cpe/ugw-prepare-all.sh -o
	[[ $delete == 1 ]] && {
		echb "ugw_prepare_clean: repo_delete_all_branches"
		repo_delete_all_branches
	}
	echb "ugw_prepare_clean: repo sync"
	repo sync
	[[ -n "$branch" ]] && {
		echb "ugw_prepare_clean: repo_checkout_feature_branch $branch"
		repo_checkout_feature_branch $branch
	}
	echb "ugw_prepare_clean: ../../config_cpe/ugw-prepare-all.sh"
	../../config_cpe/ugw-prepare-all.sh
	[[ -n "$model" ]] && {
		echb "./scripts/ltq_change_environment.sh switch ./ugw/config/$model"
		./scripts/ltq_change_environment.sh switch $model
		[[ $toolchain == 1 ]] && {
			echb "ugw_prepare_clean: ./scripts/ltq_set_ext_toolchain.sh"
			${env_dir}/ltq_set_ext_toolchain.sh
		}
	}
	echr "ugw_prepare_clean: DONE"
}

function gittagi()
{
        local tag_name
        tag_name=integration_`git rev-parse --abbrev-ref HEAD`_`date +%Y%m%dT%H%M00%z`
        git tag "$tag_name"
        echo "You are going to push tag: $tag_name; press enter or ctrl+D to abort";read p
        [ $? != 0 ] && git tag -d "$tag_name" && return
        echo "wait..."
        git push "$(git remote show)" "$tag_name"
        echo "############## tag: $tag_name push complete ##############" 
} 