Running Mkbootstrap for run_base64_pl_9e2c ()
chmod 644 "run_base64_pl_9e2c.bs"
"/usr/bin/perl" -MExtUtils::Command::MM -e 'cp_nonempty' -- run_base64_pl_9e2c.bs blib/arch/auto/run_base64_pl_9e2c/run_base64_pl_9e2c.bs 644
"/usr/bin/perl" "/usr/share/perl5/ExtUtils/xsubpp"  -typemap "/usr/share/perl5/ExtUtils/typemap"   run_base64_pl_9e2c.xs > run_base64_pl_9e2c.xsc
mv run_base64_pl_9e2c.xsc run_base64_pl_9e2c.c
gcc -c  -I"/home/xing/all_bak/perl/inline" -D_REENTRANT -D_GNU_SOURCE -fno-strict-aliasing -pipe -fstack-protector -I/usr/local/include -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic   -DVERSION=\"0.00\" -DXS_VERSION=\"0.00\" -fPIC "-I/usr/lib64/perl5/CORE"   run_base64_pl_9e2c.c
run_base64_pl_9e2c.xs: In function ‘main_’:
run_base64_pl_9e2c.xs:8: error: ‘argc’ undeclared (first use in this function)
run_base64_pl_9e2c.xs:8: error: (Each undeclared identifier is reported only once
run_base64_pl_9e2c.xs:8: error: for each function it appears in.)
run_base64_pl_9e2c.xs:13: warning: implicit declaration of function ‘ch_to_base64’
make: *** [run_base64_pl_9e2c.o] Error 1
