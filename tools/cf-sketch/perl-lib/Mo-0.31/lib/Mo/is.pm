package Mo::is;$M="Mo::";
$VERSION=0.31;
*{$M.'is::e'}=sub{my($P,$e,$o)=@_;$o->{is}=sub{my($m,$n,%a)=@_;$a{is}or return$m;sub{$#_&&$a{is}eq 'ro'&&caller ne 'Mo::coerce'?die$n.' is ro':$m->(@_)}}};
