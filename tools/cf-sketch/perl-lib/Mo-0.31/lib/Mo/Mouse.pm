package Mo::Mouse;$M="Mo::";
$VERSION=0.31;
*{$M.'Mouse::e'}=sub{my($P,$e)=@_;$P=~s/::$//;%$e=(M=>1);require Mouse;require Mouse::Util::MetaRole;Mouse->import({into=>$P});Mouse::Util::MetaRole::apply_metaroles(for=>$P,class_metaroles=>{attribute=>['Attr::Trait']},)};BEGIN{package Attr::Trait;use Mouse::Role;around _process_options=>sub{my$orig=shift;my$c=shift;my($n,$o)=@_;$o->{is}||='rw';$o->{lazy}||=1 if defined$o->{default}or defined$o->{builder};$c->$orig(@_)};$INC{'Attr/Trait.pm'}=1}
