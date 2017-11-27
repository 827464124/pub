use ExtUtils::MakeMaker;
my %options = %{
{
  'TYPEMAPS' => [
    '/usr/share/perl5/ExtUtils/typemap'
  ],
  'NAME' => 'run_base64_pl_8b7e',
  'INC' => '-I"/home/xing/all_bak/perl/inline"',
  'LIBS' => [
    '-lbase64'
  ],
  'VERSION' => '0.00'
}
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
