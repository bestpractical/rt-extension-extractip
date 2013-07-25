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

You B<have to> create an action record, see L</CONFIGURATION>.

=head1 INSTALLATION

Usual steps:

    perl Makefile.PL
    make
    make install

=head1 CONFIGURATION

Enable plugin in the config first:

    Set(@Plugins, 'RT::Extension::ExtractIP', ... other plugins ...);

Scrip action record should be created, the easiest way is to use initialdata
like file:

    @ScripActions = (
        {  Name        => 'Extract IPs into IP CF',    # loc
           Description => 'Extracts IPv4, IPv6 and CIDRs from messages into IP custom field',
           ExecModule  => 'ExtractIP',
           Argument    => '',
        },
    );

Argument can be used to set CF name and other options, see L<RT::Action::ExtractIP>.

Insert content of the file into DB using F<sbin/rt-setup-database>:

    ./sbin/rt-setup-database --action insert --datafile /path/to/file/you/created/above

After this step you can create a new scrip using action you created above.

=head1 AUTHOR

Ruslan Zakirov E<lt>ruz@bestpractical.comE<gt>

=head1 LICENSE

Under the same terms as perl itself.

=cut

1;