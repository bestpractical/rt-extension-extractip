use v5.8;
use strict;
use warnings;

package RT::Extension::ExtractIP;

our $VERSION = '0.01';

=head1 NAME

RT::Extension::ExtractIP - extracts IP, IP ranges and CIDRs from messages

=head1 DESCRIPTION

This extension consist of scrip action that extracts IP adresses, IP ranges
CIDR from messages and puts them into a custom field.

=head1 INSTALLATION

Usual steps:

    perl Makefile.PL
    make
    make install

=head1 CONFIGURATION

Enable plugin in the config first:

    Set(@Plugins, 'RT::Extension::ExtractIP', ... other plugins ...);

=head1 AUTHOR

Ruslan Zakirov E<lt>ruz@bestpractical.comE<gt>

=head1 LICENSE

Under the same terms as perl itself.

=cut

1;