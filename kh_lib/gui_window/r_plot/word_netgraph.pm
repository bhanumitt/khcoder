package gui_window::r_plot::word_netgraph;
use base qw(gui_window::r_plot);

sub start{
	my $self = shift;
	
	return 1 if $::config_obj->web_if;
	
	# make a button for interactive html
	$self->{button_interactive} = $self->{bottom_frame}->Button(
		-text => kh_msg->get('interactive'), # interactive html
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub {
			my $html = $::project_obj->file_TempHTML;
			$self->{plots}[$self->{ax}]->save($html);
			gui_OtherWin->open($html);
		}
	)->pack(-side => 'right');
	
	$self->win_obj->bind(
		'<Key-h>',
		sub{
			$self->{button_interactive}->flash;
			$self->{button_interactive}->invoke;
		}
	);
	
	# read coordinates
	return 0 unless -e $self->{coord};
	@{$self->{coordi}} = ();
	open(my $fh, '<:encoding(utf8)', $self->{coord}) or die("file: $self->{coord}");
	while (<$fh>) {
		chomp;
		push @{$self->{coordi}}, [split /\t/, $_];
	}
	close $fh;

	# make clickable image map
	my ($mag, $xmag, $xo, $yo, $tw, $th) = (1.0275, 0.983, 9, 10, 30, 11);
	$xo = $xo * $self->{img_height} / 640;
	$yo = $yo * $self->{img_height} / 640;
	$tw = $tw * $self->{img_height} / 640;
	$th = $th * $self->{img_height} / 640;
	
	# adjustments for X-Y ratio
	$self->{ratio} = $self->{ratio} - 0.04629629629;
	if ($self->{ratio}) {
		print "ratio: $self->{ratio}\n";
		if ($self->{ratio} > 1.01 ) { # width is longer
			if ($self->{ratio} < 1) {
				$self->{ratio} = 1;
			}
			$yo = $yo +
				( ( $self->{img_height} - $yo ) / $mag ) * ( 1 -  1 / $self->{ratio} ) / 2;
			$mag = $mag * $self->{ratio};
			#$yo = $yo * 0.88; # umm...
			#$mag = $mag * 0.96; # umm...
		}
		elsif ($self->{ratio} < 0.99 ){ # height is longer
			$xo = $xo +
				( ( $self->{img_height} - $xo ) / $mag ) * ( 1 - $self->{ratio} ) / 2;
			$xmag = $xmag / $self->{ratio};
			#$xo = $xo * 1.00; # umm...
			$xmag = $xmag * 0.98; # umm...
		}
		#print "$xo, $yo, $mag, $xmag\n";
	}
	
	$self->{coordin} = {};
	foreach my $i (@{$self->{coordi}}){
		my $x1 = $i->[1] * $self->{img_height} / $xmag + $xo - $tw;
		my $y1 = $self->{img_height} - ($i->[2] * $self->{img_height} / $mag  + $yo + $th);
		my $x2 = $i->[1] * $self->{img_height} / $xmag + $xo + $tw;
		my $y2 = $self->{img_height} - ($i->[2] * $self->{img_height} / $mag + $yo - $th);
		
		$x1 = int($x1);
		$x2 = int($x2);
		$y1 = int($y1);
		$y2 = int($y2);
		
		my $id = $self->{canvas}->createRectangle(
			$x1,$y1, $x2, $y2,
			-outline => ""
		);
		
		$self->{canvas}->bind(
			$id,
			"<Enter>",
			sub { $self->decorate($id); }
		);
		$self->{canvas}->bind(
			$id,
			"<Button-1>",
			sub { $self->show_kwic($id); }
		);
		$self->{canvas}->bind(
			1,
			"<Button-1>",
			sub { $self->undecorate; }
		);
		
		$self->{coordin}{$id} = {
			'x1' => $x1,
			'x2' => $x2,
			'y1' => $y1,
			'y2' => $y2,
			'name' => $i->[0],
		};
	}
}

sub illuminate{
	my $self = shift;
	
	return 0 unless ( defined($self->{coordin}) );
	
	$self->{win_obj}->update;
	
	use Time::HiRes 'sleep';
	my @ills = ();
	my $n = 1;
	foreach my $i (
		sort {
			$self->{coordin}{$a}{y1} 
			<=>
			$self->{coordin}{$b}{y1} 
		}
		keys %{$self->{coordin}}
	){
		push @ills, $self->{canvas}->createRectangle(
			$self->{coordin}{$i}{x1} -1,
			$self->{coordin}{$i}{y1} +1,
			$self->{coordin}{$i}{x2} +1,
			$self->{coordin}{$i}{y2} -1,
			-outline => '#778899',
			-width   => 1,
		);
		$self->{canvas}->update;
		
		sleep 1 / (  $n * $n + 30 );
		++$n;
	}
	
	sleep 0.5;
	
	foreach my $i (reverse @ills){
		$self->{canvas}->delete( $i );
	}
	$self->{canvas}->update;
}


sub option1_options{
	my $self = shift;
	
	if (@{$self->{plots}} == 2){
		return [
			kh_msg->get('gui_window::r_plot::word_netgraph->col'), # カラー
			kh_msg->get('gui_window::r_plot::word_netgraph->gray'), # グレー
		] ;
	}
	elsif (@{$self->{plots}} == 3){
		return [
			kh_msg->get('gui_window::r_plot::word_netgraph->cnt_b'),
			kh_msg->get('gui_window::r_plot::word_netgraph->com_r'),
			kh_msg->get('gui_window::r_plot::word_netgraph->com_m'), # サブグラフ検出（modularity）
		];
	}
	elsif (@{$self->{plots}} == 4){
		return [
			kh_msg->get('gui_window::r_plot::word_netgraph->cnt_b'),
			kh_msg->get('gui_window::r_plot::word_netgraph->com_r'),
			kh_msg->get('gui_window::r_plot::word_netgraph->com_m'), # サブグラフ検出（modularity）
			kh_msg->get('gui_window::r_plot::word_netgraph->cor'),  # 相関
		];
	}
	elsif (@{$self->{plots}} == 8){
		return [
			kh_msg->get('gui_window::r_plot::word_netgraph->cnt_b'), # 中心性（媒介）
			kh_msg->get('gui_window::r_plot::word_netgraph->cnt_d'), # 中心性（次数）
			kh_msg->get('gui_window::r_plot::word_netgraph->cnt_v'), # 中心性（固有ベクトル）
			kh_msg->get('gui_window::r_plot::word_netgraph->com_b'), # サブグラフ検出（媒介）
			kh_msg->get('gui_window::r_plot::word_netgraph->com_r'),
			kh_msg->get('gui_window::r_plot::word_netgraph->com_m'), # サブグラフ検出（modularity）
			kh_msg->get('gui_window::r_plot::word_netgraph->cor'),  # 相関
			kh_msg->get('gui_window::r_plot::word_netgraph->none'),  # なし
		];
	} else {
		return [
			kh_msg->get('gui_window::r_plot::word_netgraph->cnt_b'), # 中心性（媒介）
			kh_msg->get('gui_window::r_plot::word_netgraph->cnt_d'), # 中心性（次数）
			kh_msg->get('gui_window::r_plot::word_netgraph->cnt_v'), # 中心性（固有ベクトル）
			kh_msg->get('gui_window::r_plot::word_netgraph->com_b'), # サブグラフ検出（媒介）
			kh_msg->get('gui_window::r_plot::word_netgraph->com_r'),
			kh_msg->get('gui_window::r_plot::word_netgraph->com_m'), # サブグラフ検出（modularity）
			kh_msg->get('gui_window::r_plot::word_netgraph->none'),  # なし
		];
	}

}

sub save{
	my $self = shift;

	# 保存先の参照
	my @types = (
		[ "PDF",[qw/.pdf/] ],
		[ "Encapsulated PostScript",[qw/.eps/] ],
		[ "SVG",[qw/.svg/] ],
		[ "PNG",[qw/.png/] ],
		[ "GraphML",[qw/.graphml/] ],
		[ "Pajek",[qw/.net/] ],
		[ "Interactive HTML",[qw/.html/] ],
		[ "R Source",[qw/.r/] ],
	);
	@types = ([ "Enhanced Metafile",[qw/.emf/] ], @types)
		if $::config_obj->os eq 'win32';

	my $path = $self->win_obj->getSaveFile(
		-defaultextension => '.pdf',
		-filetypes        => \@types,
		-title            =>
			$self->gui_jt(kh_msg->get('gui_window::r_plot->saving')), # プロットを保存
		-initialdir       => $self->gui_jchar($::config_obj->cwd)
	);

	$path = $self->gui_jg_filename_win98($path);
	$path = $self->gui_jg($path);
	$path = $::config_obj->os_path($path);

	$self->{plots}[$self->{ax}]->save($path) if $path;

	return 1;
}

sub option1_name{
	return kh_msg->get('gui_window::r_plot::word_netgraph->color'); #  カラー：
}

sub win_title{
	return kh_msg->get('win_title'); # 抽出語・共起ネットワーク
}

sub win_name{
	return 'w_word_netgraph_plot';
}


sub base_name{
	return 'word_netgraph';
}

1;