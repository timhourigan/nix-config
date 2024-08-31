{ config, pkgs, ... }:

{

  # Allow necessary ports through the firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 8123 1883 ]; # 8123:Home Assistant; 1883:Mosquitto
  };

  # Enable Podman
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true; # Docker alias
    };
  };

  virtualisation.oci-containers = {
    backend = "podman";
    containers.homeassistant = {
      autoStart = true;
      volumes = [ "home-assistant:/config" ];
      environment.TZ = "Europe/Dublin";
      image = "ghcr.io/home-assistant/home-assistant:2024.7.1";
      extraOptions = [
        "--network=host"
        "--device=/dev/ttyUSB0:/dev/ttyUSB0"
      ];
    };
  };



  #    services.home-assistant = {
  #      enable = true;
  #      extraComponents = [
  #        # Components required to complete the onboarding
  #        "met"
  #        "radio_browser"
  #        "mqtt"
  #      ];
  #      config = {
  #        # Includes dependencies for a basic setup
  #        # https://www.home-assistant.io/integrations/default_config/
  #        default_config = {};
  #      };
  #    };


  #   services.mosquitto = {
  #     enable = true;
  #     listeners = [
  #       {
  #         acl = [ "pattern readwrite #" ];
  #         omitPasswordAuth = true;
  #         settings.allow_anonymous = true;
  #       }
  #     ];
  #   };

  #   #services.mosquitto = {
  #   #  enable = true;
  #   #  users = {
  #   #    ha = {
  #   #      acl = [ "topic readwrite #" ];
  #   #      password = "hapass";
  #   #    };
  #   #  };
  #   #listeners = [ {
  #   #  users = {
  #   #    monitor = {
  #   #      acl = [ "read #" ];
  #   #      password = "monitor";
  #   #    };
  #   #    service = {
  #   #      acl = [ "write service/#" ];
  #   #      password = "service";
  #   #    };
  #   #  };
  #   #} ];
  #   #};


  #   virtualisation = {
  #     podman = {
  #       enable = true;

  #       # Create a `docker` alias for podman, to use it as a drop-in replacement
  #       dockerCompat = true;

  #       # Required for containers under podman-compose to be able to talk to each other.
  #       defaultNetwork.dnsname.enable = true;
  #     };
  #   };

  #   virtualisation.oci-containers = {
  #     backend = "podman";
  #     containers.homeassistant = {
  #       autoStart = true;
  #       volumes = [ "home-assistant:/config" ];
  #       environment.TZ = "Europe/Dublin";
  #       image = "ghcr.io/home-assistant/home-assistant:2024.8.3"; # Warning: if the tag does not change, the image will not be updated
  #       extraOptions = [
  #         "--network=host"
  #         "--device=/dev/ttyUSB0:/dev/ttyUSB0"
  #       ];
  #     };
  #   };
}
