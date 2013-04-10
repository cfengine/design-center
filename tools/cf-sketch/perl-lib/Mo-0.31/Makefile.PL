use inc::Module::Package 'Ingy:modern 0.17';

# Inline this to keep Mo.pm minimal:
name 'Mo';
module_name 'Mo';
perl_version '5.006';
all_from 'lib/Mo.pm';
all_from 'lib/Mo.pod';

recommends 'IO::All';
recommends 'Class::XSAccessor';
recommends 'Moose';
recommends 'Mouse';

no_index 'directory' => 'src';
