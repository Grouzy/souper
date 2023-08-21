#!/bin/bash -e

# Copyright 2014 The Souper Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

if [ -d "third_party" ]; then
  echo "Directory third_party exists, remove this directory before running build_deps.sh."
  exit 1;
fi

ncpus=$(command nproc 2>/dev/null || command sysctl -n hw.ncpu 2>/dev/null || echo 8)

# hiredis latest as of May 7 2021
klee_repo=https://github.com/Grouzy/klee
klee_branch=master
alive_repo=https://github.com/Grouzy/alive2.git
hiredis_repo=https://github.com/Grouzy/hiredis

llvm_build_type=Release
if [ -n "$1" ] ; then
  llvm_build_type="$1"
  shift
fi

alivedir=$(pwd)/third_party/alive2
alive_builddir=$alivedir/build
git clone $alive_repo $alivedir
mkdir -p $alive_builddir

if [ -n "`which ninja`" ] ; then
  (cd $alive_builddir && cmake .. -DCMAKE_BUILD_TYPE=$llvm_build_type -GNinja)
  ninja -C $alive_builddir
else
  (cd $alive_builddir && cmake ../alive2 -DCMAKE_BUILD_TYPE=$llvm_build_type)
  make -C $alive_builddir -j $ncpus
fi

kleedir=$(pwd)/third_party/klee
git clone $klee_repo $kleedir

hiredis_srcdir=$(pwd)/third_party/hiredis
hiredis_installdir=$hiredis_srcdir/build
git clone $hiredis_repo $hiredis_srcdir

mkdir -p $hiredis_installdir/include/hiredis
mkdir -p $hiredis_installdir/lib

(cd $hiredis_srcdir && make libhiredis.a &&
 cp -r alloc.h hiredis.h async.h read.h sds.h adapters ${hiredis_installdir}/include/hiredis &&
 cp libhiredis.a ${hiredis_installdir}/lib)
