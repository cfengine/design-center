package Mo::import;my$M="Mo::";
$VERSION=0.31;
my$i=\&import;*{$M.import}=sub{(@_==2 and not $_[1])?pop@_:@_==1?push@_,grep!/import/,@f:();goto&$i};
