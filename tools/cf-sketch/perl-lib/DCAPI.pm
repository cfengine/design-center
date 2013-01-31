package DCAPI;

use JSON;
use File::Which;

use constant API_VERSION => '0.0.1';
use constant SKETCH_DEF_FILE => 'sketch.json';
use constant CODER => JSON->new()->relaxed()->utf8()->allow_nonref();
use constant CAN_CODER => JSON->new()->canonical()->utf8()->allow_nonref();

use Mo qw/build default builder coerce is required/;

# has name2 => ( builder => 'name_builder' );
# has name3 => ( coerce => sub {$_[0]} );
# has name4 => ( required => 1 );
# sub BUILD {
#     my $self = shift;
#     ...
# }

has version => ( is => 'ro', default => sub { API_VERSION } );

has config => ( );

has curl => ( is => 'ro', default => sub { which('curl') } );

has coder =>
 (
  is => 'ro',
  default => sub { CODER },
 );

has canonical_coder =>
 (
  is => 'ro',
  default => sub { CAN_CODER },
 );

sub set_config
{
 my $this = shift @_;
 my $file = shift @_;

 $this->config($this->load($file));
}

sub log { shift; print STDERR @_; };

sub decode { shift; CODER->decode(@_) };
sub encode { shift; CODER->encode(@_) };
sub cencode { shift; CAN_CODER->encode(@_) };

sub curl_GET { shift->curl('GET', @_) };

sub curl
{
 my $this = shift @_;
 my $mode = shift @_;
 my $url = shift @_;

 my $curl = $this->curl();

 my $run = <<EOHIPPUS;
$curl -s $mode $url |
EOHIPPUS

 $this->log("Running: $run\n");

 open my $c, $run or return (undef, "Could not run command [$run]: $!");

 return ([<$c>], undef);
};

sub load
{
 my $this = shift @_;
 my $f = shift @_;

 my @j;

 my $try_eval;
 eval
 {
  $try_eval = $this->decode($f);
 };

 if ($try_eval) # detect inline content, must be proper JSON
 {
  return ($try_eval);
 }
 elsif (Util::is_resource_local($f))
 {
  my $j;
  unless (open($j, '<', $f) && $j)
  {
   return (undef, "Could not inspect $f: $!");
  }

  @j = <$j>;
 }
 else
 {
  my ($j, $error) = $this->curl_GET($f);

  defined $error and return (undef, $error);
  defined $j or return (undef, "Unable to retrieve $f");

  @j = @$j;
 }

 if (scalar @j)
 {
  chomp @j;
  s/\n//g foreach @j;
  s/^\s*(#|\/\/).*//g foreach @j;

  my $ret = $this->decode(join '', @j);

  return ($ret);
 }

 return (undef, "No data was loaded from $f");
}

sub ok
{
 my $this = shift;
 print $this->encode($this->make_ok(@_)), "\n";
}

sub exit_error
{
 shift->error(@_);
 exit 0;
}

sub error
{
 my $this = shift;
 print $this->encode($this->make_error(@_)), "\n";
}

sub make_ok
{
 my $this = shift;
 my $ok = shift;
 $ok->{success} = JSON::true;
 $ok->{errors} ||= [];
 $ok->{warnings} ||= [];
 $ok->{log} ||= [];
 return { api_ok => $ok };
}

sub make_not_ok
{
 my $this = shift;
 my $nok = shift;
 $nok->{success} = JSON::false;
 $nok->{errors} ||= shift @_;
 $nok->{warnings} ||= shift @_;
 $nok->{log} ||= shift @_;
 return { api_not_ok => $nok };
}

sub make_error
{
 my $this = shift;
 return { api_error => [@_] };
}


1;
