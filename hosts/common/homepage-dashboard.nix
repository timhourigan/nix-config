_:

# Homepage Dashboard
# https://gethomepage.dev
# https://mynixos.com/nixpkgs/options/services.homepage-dashboard

# Icons
# https://gethomepage.dev/configs/services/#icons
# https://simpleicons.org
# https://selfh.st/icons

{
  bookmarks = [
    {
      Tech = [
        {
          Github = [{
            icon = "si-github";
            href = "https://github.com";
          }];
        }
        {
          "Nixos Search" = [{
            icon = "si-nixos";
            href = "https://search.nixos.org/packages";
          }];
        }
        {
          "Nixos Wiki" = [{
            icon = "si-nixos";
            href = "https://nixos.wiki";
          }];
        }
      ];
    }
  ];

  services = [
    {
      Appliances = [
        {
          "Larry Vacuum" = {
            description = "Downstairs Vacuum";
            icon = "sh-valetudo";
            href = "{{HOMEPAGE_VAR_LARRY_VALETUDO_URL}}";
          };
        }
        {
          "Harry Vacuum" = {
            description = "Upstairs Vacuum";
            icon = "sh-valetudo";
            href = "{{HOMEPAGE_VAR_HARRY_VALETUDO_URL}}";
          };
        }
      ];
    }
    {
      Home = [
        {
          "Home Assistant" = {
            description = "Home Automation";
            icon = "sh-home-assistant";
            href = "{{HOMEPAGE_VAR_HOME_ASSISTANT_URL}}";
          };
        }
      ];
    }
    {
      Media = [
        {
          "Lyrion" = {
            description = "Music Server";
            icon = "sh-lyrion-music-server";
            href = "{{HOMEPAGE_VAR_LYRION_URL}}";
          };
        }
        {
          "Television" = {
            description = "STB Interface";
            icon = "mdi-television";
            href = "{{HOMEPAGE_VAR_ENIGMA_STB_URL}}";
          };
        }
      ];
    }
    {
      Monitoring = [
        {
          "Glances" = {
            description = "System Monitoring";
            icon = "sh-glances";
            href = "{{HOMEPAGE_VAR_GLANCES_URL}}";
            widget = {
              type = "glances";
              url = "{{HOMEPAGE_VAR_GLANCES_URL}}";
              version = 4;
              metric = "cpu";
              chart = false;
            };
          };
        }
        {
          "Gatus" = {
            description = "Service Monitoring";
            icon = "sh-gatus";
            href = "{{HOMEPAGE_VAR_GATUS_URL}}";
            widget = {
              type = "gatus";
              url = "{{HOMEPAGE_VAR_GATUS_URL}}";
            };
          };
        }
      ];
    }
    {
      Networking = [
        {
          "Pi-Hole 1" = {
            description = "Ad Blocker";
            icon = "sh-pi-hole";
            href = "{{HOMEPAGE_VAR_PI_HOLE_1_URL}}/admin";
            widget = {
              type = "pihole";
              url = "{{HOMEPAGE_VAR_PI_HOLE_1_URL}}";
              version = 6;
              key = "{{HOMEPAGE_VAR_PI_HOLE_1_API_KEY}}";
            };
          };
        }
        {
          "Pi-Hole 2" = {
            description = "Ad Blocker";
            icon = "sh-pi-hole";
            href = "{{HOMEPAGE_VAR_PI_HOLE_2_URL}}/admin";
            widget = {
              type = "pihole";
              url = "{{HOMEPAGE_VAR_PI_HOLE_2_URL}}";
              version = 6;
              key = "{{HOMEPAGE_VAR_PI_HOLE_2_API_KEY}}";
            };
          };
        }
        {
          "Zigbee2MQTT" = {
            description = "Zigbee to MQTT Bridge";
            icon = "sh-zigbee2mqtt";
            href = "{{HOMEPAGE_VAR_ZIGBEE2MQTT_URL}}";
          };
        }
      ];
    }
    {
      News = [
        {
          "FreshRSS" = {
            description = "News";
            icon = "sh-freshrss";
            href = "{{HOMEPAGE_VAR_FRESHRSS_URL}}";
            widget = {
              type = "freshrss";
              url = "{{HOMEPAGE_VAR_FRESHRSS_URL}}";
              username = "{{HOMEPAGE_VAR_FRESHRSS_USERNAME}}";
              password = "{{HOMEPAGE_VAR_FRESHRSS_API_KEY}}";
            };
          };
        }
      ];
    }
  ];

  # Settings - https://gethomepage.dev/configs/settings
  settings = {
    title = "{{HOMEPAGE_VAR_TITLE}}";
    description = "{{HOMEPAGE_VAR_DESCRIPTION}}";
    background = "{{HOMEPAGE_VAR_BACKGROUND}}";
    theme = "dark";
    color = "stone";
    layout = [
      {
        Media = {
          tab = "Applications";
          style = "row";
          columns = "2";
        };
      }
      {
        Home = {
          tab = "Applications";
        };
      }
      {
        News = {
          tab = "Applications";
        };
      }
      {
        Monitoring = {
          tab = "System";
        };
      }
      {
        Networking = {
          tab = "System";
          style = "row";
          columns = "3";
        };
      }
      {
        Appliances = {
          tab = "System";
          style = "row";
          columns = "2";
        };
      }
      {
        Tech = {
          tab = "System";
          style = "row";
          columns = "3";
        };
      }
    ];
  };

  # Widgets - https://gethomepage.dev/widgets
  widgets = [
    {
      resources = {
        cpu = true;
        disk = "/";
        memory = true;
      };
    }
    {
      search = {
        provider = "{{HOMEPAGE_VAR_SEARCH_PROVIDER}}";
        target = "_blank";
      };
    }
  ];
}
