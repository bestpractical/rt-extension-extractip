use inc::Module::Install;

RTx('RT-Extension-ExtractIP');
all_from('lib/RT/Extension/ExtractIP.pm');

WriteAll();