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
      Dev = [
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
      "Media" = [
        {
          "Lyrion" = {
            description = "Music Server";
            icon = "sh-lyrion-media-server";
            href = "{{HOMEPAGE_VAR_LYRION_URL}}";
          };
        }
      ];
    }
    {
      "Home" = [
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
      "Networking" = [
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
      ];
    }
    {
      "Monitoring" = [
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
  ];

  # Settings - https://gethomepage.dev/configs/settings
  settings = {
    title = "{{HOMEPAGE_VAR_TITLE}}";
    description = "{{HOMEPAGE_VAR_DESCRIPTION}}";
    background = "{{HOMEPAGE_VAR_BACKGROUND}}";
    theme = "dark";
    color = "stone";
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
