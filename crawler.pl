use Modern::Perl;
use autodie;
use LWP::UserAgent;
use pQuery;
use Text::Template;

$|=1;
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
my $template = join('', <DATA>);
$template = Text::Template->new(TYPE => 'STRING', SOURCE => $template)
    or die("Can't construct template!\n");
my $ua = LWP::UserAgent->new;
my $feed = $ua->get('http://feeds.feedburner.com/VirtualJUG?format=xml');
die $feed->status_line unless $feed->is_success;
my $max_page_id = extract_max_page_id($feed->decoded_content);

say STDERR "Maximum page id: $max_page_id";

print << 'EOC';
<html>
<head>
<meta charset="utf-8" />
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<style>
@media all {
	.page-break	{ display: none; }
}

@media print {
	.page-break	{ display: block; page-break-before: always; }
}
</style>
</head>
<body>
EOC

for my $page_id (reverse 1 .. $max_page_id) {
    my $page = $ua->get("http://virtualjug.com/?p=$page_id");
    next unless $page->is_success;

    say STDERR "?p=$page_id => " . $page->base;
    my $p = pQuery($page->decoded_content);
    my $video = extract_video($p);
    next unless $video;

    my $title = extract_title($p);
    next unless $title;

    my $description = extract_description($p);
    next unless $description;

    print $template->fill_in(HASH => {
        title => $title,
        youtube_id => $video,
        description => $description,
        url => "http://virtualjug.com/?p=$page_id",
    });
}

print "</body></html>\n";

sub extract_video {
    my $p = shift;

    my $video = $p->find('div.post-video iframe');
    unless ($video->length() == 1) {
        say STDERR "Video not found: " . $video->length();
        return;
    }

    $video = $video->[0]->getAttribute('src');
    unless ($video =~ /\/\/www.youtube.com\/embed\/(.*)/) {
        say STDERR "Unknown video URL: $video";
        return;
    }
    $video = $1;
    say STDERR "Video: $video";

    return $video;
}

sub extract_title {
    my $p = shift;

    my $title = $p->find('div.post-content h1.masonry-title');
    unless ($title->length() == 1) {
        say STDERR "Title not found: " . $title->length();
        return;
    }
    $title = trim($title->[0]->innerHTML());
    say STDERR "Title: $title";

    return $title;
}

sub extract_description {
    my $p = shift;

    my $description = $p->find('div.post-content div.share-options ~ p:first');
    unless ($description->length() == 1) {
        say STDERR "Description not found: " . $description->length();
        next;
    }
    $description = trim($description->[0]->innerHTML());
    $description =~ s/<span id="more-\d+"><\/span>//g;
    say STDERR "Description length: " . length($description);

    return $description;
}

sub trim {
    my $s = shift;
    $s =~ s/^\s+//; $s =~ s/\s+$//;
    return $s;
}

sub extract_max_page_id {
    my $feed_xml = shift;
    my $max_id = 0;
    while ($feed_xml =~ /http:\/\/virtualjug.com\/\?p=(\d+)/g) {
        next unless $1 > $max_id;
        $max_id = $1;
    }
    return $max_id;
}

__DATA__
<center style="padding-top: 10px">
<table width="320">
<tr><td colspan="2">
<h2>{$title}</h2>
</td></tr>

<tr><td colspan="2">

<p><img style="width: 500px; height: auto;" src="https://img.youtube.com/vi/{$youtube_id}/maxresdefault.jpg" />
</td></tr>

<tr><td colspan="2">
<br>

<p>{$description}</p>

<br>
<br>

</td></tr>

<tr valign="top">
<td>
<p><img src="http://virtualjug.com/wp-content/uploads/2014/04/Vjug.png" />

</td>
<td align="right">
<p><a href="{$url}">{$url}</a>
<p><img src="https://api.qrserver.com/v1/create-qr-code/?size=150x150&data={$url}" />
</td></tr>

</table>
</center>
<div class="page-break"></div>
