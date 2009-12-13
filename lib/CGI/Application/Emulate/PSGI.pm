package CGI::Application::Emulate::PSGI;

use 5.008;
use strict;
use warnings;
use CGI;

our $VERSION = '0.01';

sub handler {
    my ($class, $code,) = @_;
    
    return sub {
        my $env = shift;
        my $environment = {
            GATEWAY_INTERFACE => 'CGI/1.1',
            # not in RFC 3875
            HTTPS => ( ( $env->{'psgi.url_scheme'} eq 'https' ) ? 'ON' : 'OFF' ),
            SERVER_SOFTWARE => "CGI-Emulate-PSGI",
            REMOTE_ADDR     => '127.0.0.1',
            REMOTE_HOST     => 'localhost',
            REMOTE_PORT     => int( rand(64000) + 1000 ),    # not in RFC 3875
            # REQUEST_URI     => $uri->path_query,             # not in RFC 3875
            ( map { $_ => $env->{$_} } grep !/^psgi\./, keys %$env ),
            CGI_APP_RETURN_ONLY => 1,
        };
        my $output = do {
            local *STDIN  = $env->{'psgi.input'};
            local *STDERR = $env->{'psgi.errors'};
            local @ENV{keys %$environment} = values %$environment;
            CGI::initialize_globals();
            $code->();
        };
        my $status = 200;
        my ($headers, $body) = split /\r\n\r\n/, $output, 2;
        my @headers = map { split /:\s*/, $_, 2 } split /\r\n/, $headers;
        for (my $i = 0; $i < @headers;) {
            if ($headers[$i] =~ /^status$/i) {
                $status = $headers[$i + 1];
                $status =~ s/\s+.*$//; # only keep the digits
                splice @headers, $i, 2;
            } else {
                $i += 2;
            }
        }
        return [
            $status,
            \@headers,
            [ $body ],
        ];
    };
}

1;
__END__

=head1 NAME

CGI::Application::Emulate::PSGI - Legacy-friendly PSGI adapter for CGI::Application

=head1 SYNOPSIS

    my $app = CGI::Application::Emulate::PSGI->handler(sub {
        my $webapp = WebApp->new();
        $webapp->run();
    });

=cut
