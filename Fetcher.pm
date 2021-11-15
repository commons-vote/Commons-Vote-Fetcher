package Commons::Vote::Fetcher;

use strict;
use warnings;

use Class::Utils qw(set_params);
use DateTime::Format::Strptime;
use MediaWiki::API;

our $VERSION = 0.01;

sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# MediaWiki api.
	$self->{'mw_api'} = 'https://commons.wikimedia.org/w/api.php';

	# Process parameters.
	set_params($self, @params);

	$self->{'_mw'} = MediaWiki::API->new;
	$self->{'_mw'}->{'config'}->{'api_url'} = $self->{'mw_api'};

	$self->{'_dt_parser'} = DateTime::Format::Strptime->new(
		pattern => '%FT%T',
		time_zone => 'UTC',
	);

	return $self;
}

sub date_of_first_upload {
	my ($self, $user) = @_;

	# Query for first uploaded image.
	my $ref = $self->{'_mw'}->api({
		action => 'query',
		list => 'allimages',
		aisort => 'timestamp',
		aiuser => $user,
		ailimit => 1,
	});

	# No images.
	if (! @{$ref->{'query'}->{'allimages'}}) {
		return;
	}

	# Timestamp of first uploaded image.
	my $mw_timestamp = $ref->{'query'}->{'allimages'}->[0]->{'timestamp'};

	# Return DateTime object.
	return $self->{'_dt_parser'}->parse_datetime($mw_timestamp);
}

sub image_info {
	my ($self, $image) = @_;

	if ($image !~ m/^(File|Image):/ms) {
		$image = 'File:'.$image;
	}

	my $ref = $self->{'_mw'}->api({
		action => 'query',
		prop => 'imageinfo',
		titles => $image,
		iiprop => 'timestamp|user|size|extmetadata',
	});

	if (exists $ref->{'query'}->{'pages'}->{'-1'}) {
		return undef;
	}

	my ($pageid, $pageref) = each %{$ref->{query}->{pages}};
	my $rev_hr = $pageref->{imageinfo}->[0];

	return {
		'pageid' => $pageid,
		'height' => $rev_hr->{'height'},
		'width' => $rev_hr->{'width'},
		'comment' => $rev_hr->{'extmetadata'}->{'ImageDescription'}->{'value'},
		'artist' => $rev_hr->{'extmetadata'}->{'Artist'}->{'value'},
	};
}

sub image_upload_revision {
	my ($self, $image) = @_;

	if ($image !~ m/^(File|Image):/ms) {
		$image = 'File:'.$image;
	}

	my $ref = $self->{'_mw'}->api({
		action => 'query',
		prop => 'revisions',
		titles => $image,
		rvlimit => 1,
		rvprop => 'timestamp|user',
		rvdir => 'newer',
	});

	if (exists $ref->{'query'}->{'pages'}->{'-1'}) {
		return undef;
	}

	my ($pageid, $pageref) = each %{$ref->{query}->{pages}};
	my $rev = @{$pageref->{revisions}}[0];
	delete $pageref->{revisions};

	return {
		'pageid' => $pageid,
		%{$rev},
		%{$pageref},
	};
}

sub images_in_category {
	my ($self, $category) = @_;

	if ($category !~ m/^Category:/ms) {
		$category = 'Category:'.$category;
	}

	my $images_ar = $self->{'_mw'}->list({
                action => 'query',
                list => 'categorymembers',
                cmtitle => $category,
                cmtype => 'file',
                cmlimit => '10',
        });

	return @{$images_ar};
}

1;

__END__
