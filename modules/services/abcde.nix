{ config, lib, options, pkgs, ... }:

let
  cfg = config.packages.abcde;
in
{
  options = {
    packages.abcde = {
      enable = lib.mkEnableOption "abcde" // {
        description = "Enable abcde CD ripper package";
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      abcde
      cddiscid
      cdparanoia
      cdrtools
      flac
      glyr
      imagemagick
      lame
      vorbis-tools
    ];

    environment.etc."abcde.conf".text = ''
      # Encoder options
      MP3ENCODERSYNTAX=lame
      FLACENCODERSYNTAX=flac
      LAME=lame
      FLAC=flac
      LAMEOPTS='--preset extreme'
      FLACOPTS='--verify --best'

      # Use paranoia for reading CDs
      CDROMREADERSYNTAX=cdparanoia
      # Can be adjusted for damaged CDs
      # CDPARANOIAOPTS="--never-skip=10"

      # CD identification
      CDDISCID=cd-discid

      # mp3 and flac output
      OUTPUTTYPE="mp3,flac"

      # Output folder
      OUTPUTDIR="$HOME/Music/abcde"

      # Actions to take
      ACTIONS=cddb,playlist,read,encode,tag,move,clean
      # Optionally embed album art
      # ACTIONS=cddb,embedalbumart,playlist,read,encode,tag,move,clean


      # Lookup method
      CDDBMETHOD=musicbrainz,cddb,cdtext

      # cddb settings
      CDDBURL="http://gnudb.gnudb.org/~cddb/cddb.cgi"
      HELLOINFO="`whoami`@`hostname`"

      # cddb submission options - Not needed for musicbrainz
      # CDDBSUBMIT=freedb-submit@freedb.org
      # NOSUBMIT=n

      # Use spaces instead of underscores for naming
      mungefilename ()
      {
        echo "$@" | sed s,:,-,g | tr / _ | tr -d \'\"\?\[:cntrl:\]
      }

      # Use 01, 02, etc. for track numbers
      PADTRACKS=y

      # Use up to 4 encoders (default is 1)
      MAXPROCS=4

      # Eject once complete
      EJECTCD=y

      # Folder per album - `''\` is needed for escaping
      OUTPUTFORMAT=''\'''\${OUTPUT}/''\${ARTISTFILE}/''\${ALBUMFILE}/''\${TRACKNUM}.''\${TRACKFILE}''\'
      # Various artists under dedicated folder
      VAOUTPUTFORMAT=''\'''\${OUTPUT}/Various/''\${ALBUMFILE}/''\${TRACKNUM}.''\${ARTISTFILE}-''\${TRACKFILE}''\'
      # Playlists
      PLAYLISTFORMAT=''\'''\${OUTPUT}/''\${ARTISTFILE}/''\${ALBUMFILE}/''\${ALBUMFILE}.m3u'
      VAPLAYLISTFORMAT=''\'''\${OUTPUT}/Various/''\${ALBUMFILE}/''\${ALBUMFILE}.m3u'

      # Extra debug
      # EXTRAVERBOSE=y
    '';
  };
}
