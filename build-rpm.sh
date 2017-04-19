#!/bin/sh -xe
# runsisi AT hust.edu.cn

k_build_dir=''

trap '{ k_cleanup; }' EXIT

# helpers

k_prepare_src() {
    kversion=$(sed -n '/^\s*AC_INIT.*/p' configure.ac | cut -d, -f2 | sed 's/\s*\[\(.*\)\]\s*/\1/')

    autoconf
    ./configure

    cp ../linux-$kversion.tar.xz $k_build_dir/SOURCES/
    cp config-x86_64 $k_build_dir/SOURCES/config-$kversion-x86_64
    cp cpupower.config $k_build_dir/SOURCES/
    cp cpupower.service $k_build_dir/SOURCES/
    if ls *.patch > /dev/null 2>&1; then cp *.patch $k_build_dir/SOURCES/; fi
    cp kernel.spec $k_build_dir/SPECS/
}

k_prepare_build_env() {
    k_build_dir=$(mktemp -d --suffix .kernel.el7.x86_64.rpm)
    
    (cd $k_build_dir && mkdir BUILD  BUILDROOT  RPMS  SOURCES  SPECS  SRPMS)
}

k_cleanup_src() {
    git add -u
    git reset --hard
    git clean -df -e output
}

k_cleanup_build_env() {
    rm -rf $k_build_dir
}

# prepare -> build -> upload -> cleanup

k_prepare() {
    k_prepare_build_env
    k_prepare_src
}

k_build_rpm() {
    rpmbuild --define "_topdir $k_build_dir" -ba kernel.spec
}

k_upload_rpm() {
    rm -rf output/
    mkdir output/
    cp $k_build_dir/RPMS/x86_64/*.rpm output/
}

k_cleanup() {
    k_cleanup_build_env
    k_cleanup_src
}

# entry

main() {
    k_prepare
    k_build_rpm
    k_upload_rpm
}

main
