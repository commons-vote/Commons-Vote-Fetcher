package Commons::Vote::Fetcher;

use strict;
use warnings;

use Class::Utils qw(set_params);
use DateTime::Format::Strptime;
use English;
use Error::Pure qw(err);
use Error::Pure::Utils qw(err_msg);
use List::Util qw(none);
use MediaWiki::API;
use Wikibase::API;

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

	$self->{'_wb_api'} = Wikibase::API->new(
		'mediawiki_site' => 'commons.wikimedia.org',
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
		'artist' => $rev_hr->{'extmetadata'}->{'Artist'}->{'value'},
		'comment' => $rev_hr->{'extmetadata'}->{'ImageDescription'}->{'value'},
		'datetime_created' => $rev_hr->{'extmetadata'}->{'DateTimeOriginal'}->{'value'},
		'height' => $rev_hr->{'height'},
		'pageid' => $pageid,
		'size' => $rev_hr->{'size'},
		'width' => $rev_hr->{'width'},
	};
}

sub image_structured_data {
	my ($self, $mid) = @_;

	my $item = eval {
		$self->{'_wb_api'}->get_item($mid);
	};

	# Check if item is not available (error code: 3).
	if ($EVAL_ERROR eq 'Cannot get item.') {
		my %error = err_msg();
		if ($error{'Error code'} == 3) {
			return;
		}
		err $EVAL_ERROR, %error;
	}

	return $item;
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

	# Convert timestamp to DateTime object.
	$rev->{'timestamp'} = $self->{'_dt_parser'}->parse_datetime($rev->{'timestamp'});

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

sub images_in_category_recursive {
	my ($self, $category) = @_;

	if ($category !~ m/^Category:/ms) {
		$category = 'Category:'.$category;
	}

	my @categories = ($category);
	push @categories, map { $_->{'title'} } $self->subcats_in_category($category);

	my @images;
	foreach my $category (@categories) {
		foreach my $image_ar ($self->images_in_category($category)) {
			if (none { $image_ar->{'pageid'} eq $_->{'pageid'} } @images) {
				push @images, $image_ar;
			}
		}
	}

	return @images;
}

sub user_exists {
	my ($self, $wm_username) = @_;

	my $user_hr = $self->{'_mw'}->api({
		action => 'query',
		list => 'users',
		ususers => $wm_username,
	});

	return $user_hr->{'query'}->{'users'}->[0]->{'userid'} || undef;
}

sub subcats_in_category {
	my ($self, $category) = @_;

	if ($category !~ m/^Category:/ms) {
		$category = 'Category:'.$category;
	}

	my $categories_ar = $self->{'_mw'}->list({
                action => 'query',
                list => 'categorymembers',
                cmtitle => $category,
                cmtype => 'subcat',
                cmlimit => '10',
        });

	return @{$categories_ar};
}

1;

__END__
