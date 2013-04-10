#
# DesignCenter::API
#
# DC-specific API
#
package DesignCenter::API;

sub make_ok
{
 return { api_ok => shift };
}

sub make_error
{
 return { api_error => shift };
}

1;
