Running Mkbootstrap for run_base64_pl_8301 ()
chmod 644 "run_base64_pl_8301.bs"
"/usr/bin/perl" -MExtUtils::Command::MM -e 'cp_nonempty' -- run_base64_pl_8301.bs blib/arch/auto/run_base64_pl_8301/run_base64_pl_8301.bs 644
"/usr/bin/perl" "/usr/share/perl5/ExtUtils/xsubpp"  -typemap "/usr/share/perl5/ExtUtils/typemap"   run_base64_pl_8301.xs > run_base64_pl_8301.xsc
mv run_base64_pl_8301.xsc run_base64_pl_8301.c
gcc -c  -I"/home/xing/all_bak/perl/inline" -D_REENTRANT -D_GNU_SOURCE -fno-strict-aliasing -pipe -fstack-protector -I/usr/local/include -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic   -DVERSION=\"0.00\" -DXS_VERSION=\"0.00\" -fPIC "-I/usr/lib64/perl5/CORE"   run_base64_pl_8301.c
run_base64_pl_8301.xs:6: error: expected ‘=’, ‘,’, ‘;’, ‘asm’ or ‘__attribute__’ before ‘main_’
make: *** [run_base64_pl_8301.o] Error 1
