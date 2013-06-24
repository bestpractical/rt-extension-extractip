use strict;
use warnings;

### after: use lib qw(@RT_LIB_PATH@);
use lib qw(/opt/rt4/local/lib /opt/rt4/lib);

package RT::Extension::ExtractIP::Test;
use base 'RT::Test';

sub import {
    my $class = shift;
    my %args  = @_;

    $args{'requires'} ||= [];
    if ( $args{'testing'} ) {
        unshift @{ $args{'requires'} }, 'RT::Extension::ExtractIP';
    } else {
        $args{'testing'} = 'RT::Extension::ExtractIP';
    }

    $class->SUPER::import( %args );
    $class->export_to_level(1);
}

sub create_cf {
    my $self = shift;
    my $name = shift;

    my $cf = RT::CustomField->new( RT->SystemUser );
    $cf->Create(
        Name       => $name,
        Type       => 'IPAddress',
        LookupType => 'RT::Queue-RT::Ticket'

    );
    $cf->AddToObject( RT::Queue->new( RT->SystemUser ) );
    return $cf;
}

sub create_scrip {
    my $self = shift;

    my $action = RT::ScripAction->new( RT->SystemUser );
    my ($status, $msg) = $action->Create(
        Name => 'Extract IP',
        ExecModule => 'ExtractIP',
    );
    Test::More::ok( $status, "created action" ) or Test::More::diag("error: $msg");

    my $scrip = RT::Scrip->new(RT->SystemUser);
    ($status, $msg) = $scrip->Create(
        Description => "Test",
        Queue => 0,
        ScripCondition => 'On Transaction',
        ScripAction => 'Extract IP',
        Template => 'Blank',
        Stage => 'TransactionCreate',
    );
    Test::More::ok( $status, "created action" ) or Test::More::diag("error: $msg");

    return $scrip;
}

1;