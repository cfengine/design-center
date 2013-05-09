package dctest;

sub setup
{
    my $torun = shift @_;
    my $todo = shift @_;
    require Test;

    my $count = ref $todo eq 'HASH' ? scalar keys %$todo : 0+$todo;
    Test::plan(tests => 4+$count, todo => []);

    Test::ok(exists $ENV{CFPROMISES} && -x $ENV{CFPROMISES}, 1, "check for cf-promises");
    Test::ok(exists $ENV{CFAGENT} && -x $ENV{CFAGENT}, 1, "check for cf-agent");

    Test::ok(system($ENV{CFPROMISES}, -f => $torun), 0, "syntax check test.cf");

    open my $run, '-|', "$ENV{CFAGENT} -KI -f $torun";

    Test::ok(defined $run, 1, "run status of $torun");

    my $output = join '', <$run>;

    return $output;
}

sub matchall
{
    my $output = shift @_;
    my $todo = shift @_;

    foreach my $test (sort keys %$todo)
    {
        Test::ok($output,
                 $todo->{$test},
                 $test);
    }
}

1;
