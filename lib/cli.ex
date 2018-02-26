defmodule CLI do
  @site [
    site: [
      short: "-s",
      long: "--site",
      help: "which site to talk to",
      default: "default",
      parser: :string
    ]
  ]

  def options do
    [
      name: "unicli",
      description: "get a hand on Ubiquity's UniFi controller",
      version: "0.0.1",
      author: "Antoine POPINEAU <antoine.popineau@appscho.com>",
      allow_unknown_flags: false,
      allow_double_dash: true,
      subcommands: [
        sites: [
          name: "sites",
          description: "list all sites configured on the controller"
        ],
        devices: [
          name: "devices",
          description: "control UniFi devices",
          subcommands: [
            list: [
              name: "list",
              description: "list all adopted UniFi devices",
              options: @site
            ],
            adopt: [
              name: "adopt",
              description: "adopt a new device",
              options: @site,
              args: [
                mac: [
                  value_name: "DEVICE_MAC",
                  help: "MAC of the device to adopt",
                  required: true,
                  parser: :string
                ]
              ]
            ],
            restart: [
              name: "restart",
              description: "restart a new device",
              options: @site,
              args: [
                id: [
                  value_name: "DEVICE_ID",
                  help: "ID of the device to restart",
                  required: true,
                  parser: :string
                ]
              ]
            ],
            provision: [
              name: "provision",
              description: "force provisionning of a device",
              options: @site,
              args: [
                id: [
                  value_name: "DEVICE_ID",
                  help: "ID of the device to provision",
                  required: true,
                  parser: :string
                ]
              ]
            ],
            locate: [
              name: "locate",
              description: "enable or disable blinking of device LEDs",
              options: @site,
              args: [
                id: [
                  value_name: "DEVICE_ID",
                  help: "ID of the device to locate",
                  required: true,
                  parser: :string
                ],
                state: [
                  value_name: "STATE",
                  help: "ID of the device to locate",
                  required: true,
                  parser: fn
                    "on" -> {:ok, true}
                    "off" -> {:ok, false}
                    _ -> {:error, "only 'on' and 'off' are accepted"}
                  end
                ]
              ]
            ],
            ports: [
              name: "ports",
              description: "control device ports",
              subcommands: [
                list: [
                  name: "list",
                  description: "list all ports on a device",
                  options: @site,
                  args: [
                    id: [
                      value_name: "DEVICE_ID",
                      help: "ID of the device to inspect",
                      required: true,
                      parser: :string
                    ]
                  ]
                ],
                disable: [
                  name: "disable",
                  description: "disable a port",
                  options: @site,
                  args: [
                    device_id: [
                      value_name: "DEVICE_ID",
                      help: "ID of the device to disable a port from",
                      required: true,
                      parser: :string
                    ],
                    id: [
                      value_name: "PORT_ID",
                      help: "ID of the port to disable",
                      required: true,
                      parser: :string
                    ]
                  ]
                ],
                enable: [
                  name: "enable",
                  description: "enable a port",
                  options: @site,
                  args: [
                    device_id: [
                      value_name: "DEVICE_ID",
                      help: "ID of the device to enable a port from",
                      required: true,
                      parser: :string
                    ],
                    id: [
                      value_name: "PORT_ID",
                      help: "ID of the port to enable",
                      required: true,
                      parser: :string
                    ]
                  ]
                ]
              ]
            ]
          ]
        ],
        networks: [
          name: "networks",
          description: "control UniFi networks",
          subcommands: [
            wlan: [
              name: "wlan",
              description: "control UniFi wireless networks",
              subcommands: [
                list: [
                  name: "list",
                  description: "list all configured wireless networks",
                  options: @site
                ],
                enable: [
                  name: "enable",
                  description: "enable a specific wireless network",
                  options: @site,
                  args: [
                    id: [
                      value_name: "NETWORK_ID",
                      help: "ID of the wireless network to enable",
                      required: true,
                      parser: :string
                    ]
                  ]
                ],
                disable: [
                  name: "disable",
                  description: "disable a specific wireless network",
                  options: @site,
                  args: [
                    id: [
                      value_name: "NETWORK_ID",
                      help: "ID of the wireless network to disable",
                      required: true,
                      parser: :string
                    ]
                  ]
                ]
              ]
            ],
            list: [
              name: "list",
              description: "list all UniFi virtual networks",
              options: @site
            ]
          ]
        ],
        clients: [
          name: "clients",
          description: "control connected clients",
          subcommands: [
            list: [
              name: "list",
              description: "list all connected users",
              options: @site
            ],
            block: [
              name: "block",
              description: "block a client from the network",
              options: @site,
              args: [
                mac: [
                  value_name: "CLIENT_MAC",
                  help: "MAC address of the client to block",
                  required: true,
                  parser: :string
                ]
              ]
            ],
            unblock: [
              name: "unblock",
              description: "unblock a client from the network",
              options: @site,
              args: [
                mac: [
                  value_name: "CLIENT_MAC",
                  help: "MAC address of the client to unblock",
                  required: true,
                  parser: :string
                ]
              ]
            ],
            kick: [
              name: "kick",
              description: "kick a guest from their network",
              options: @site,
              args: [
                mac: [
                  value_name: "CLIENT_MAC",
                  help: "MAC address of the client to unauthorize",
                  required: true,
                  parser: :string
                ]
              ]
            ],
            guests: [
              name: "guests",
              description: "manage guest clients",
              subcommands: [
                authorize: [
                  name: "authorize",
                  description: "authorize a guest",
                  options: @site,
                  args: [
                    mac: [
                      value_name: "CLIENT_MAC",
                      help: "MAC address of the client to authorize",
                      required: true,
                      parser: :string
                    ]
                  ]
                ],
                unauthorize: [
                  name: "unauthorize",
                  description: "unauthorize a guest",
                  options: @site,
                  args: [
                    mac: [
                      value_name: "CLIENT_MAC",
                      help: "MAC address of the client to unauthorize",
                      required: true,
                      parser: :string
                    ]
                  ]
                ]
              ]
            ]
          ]
        ],
        vouchers: [
          name: "vouchers",
          description: "manage HotSpot vouchers",
          subcommands: [
            list: [
              name: "list",
              description: "list all active vouchers",
              options: @site
            ],
            create: [
              name: "create",
              description: "create a voucher",
              options:
                [
                  number: [
                    short: "-n",
                    help: "how many vouchers to create",
                    default: 1,
                    parser: :integer
                  ],
                  validity: [
                    short: "-e",
                    help: "validity duration (as ISO8601 durations, e.g. PT24H, etc.)",
                    default: 1440,
                    parser: fn d ->
                      case Timex.Duration.parse(d) do
                        {:error, _} -> {:error, "invalid validity duration"}
                        {:ok, seconds} -> {:ok, round(Timex.Duration.to_minutes(seconds))}
                      end
                    end
                  ],
                  usage: [
                    short: "-t",
                    help: "number of times this voucher can be used (0 for unlimited)",
                    default: 1,
                    parser: :integer
                  ],
                  comment: [
                    short: "-c",
                    help: "comment",
                    default: "Created from UniCLI"
                  ],
                  quota: [
                    short: "-q",
                    help: "usage quota in MB",
                    default: 0,
                    parser: :integer
                  ],
                  quota_download: [
                    short: "-d",
                    help: "download bandwidth limit in Kbps",
                    default: 0,
                    parser: :integer
                  ],
                  quota_upload: [
                    short: "-u",
                    help: "upload bandwidth limit in Kbps",
                    default: 0,
                    parser: :integer
                  ]
                ] ++ @site
            ],
            revoke: [
              name: "revoke",
              description: "revoke a voucher",
              options: @site,
              args: [
                id: [
                  value_name: "VOUCHER_ID",
                  help: "ID of the voucher to revoke",
                  required: true,
                  parser: :string
                ]
              ]
            ]
          ]
        ],
        radius: [
          name: "radius",
          description: "manage RADIUS users for 802.1X",
          subcommands: [
            users: [
              name: "users",
              description: "manage RADIUS users for 802.1X",
              subcommands: [
                list: [
                  name: "list",
                  description: "list all RADIUS users"
                ],
                delete: [
                  name: "delete",
                  description: "delete a RADIUS user",
                  args: [
                    id: [
                      value_name: "USER_ID",
                      help: "ID of the user to delete",
                      required: true,
                      parser: :string
                    ]
                  ]
                ],
                create: [
                  name: "create",
                  description: "create a new RADIUS user",
                  args: [
                    username: [
                      value_name: "USERNAME",
                      help: "username of the RADIUS user",
                      required: true,
                      parser: :string
                    ],
                    password: [
                      value_name: "PASSWORD",
                      help: "password of the RADIUS user",
                      required: true,
                      parser: :string
                    ]
                  ],
                  options:
                    [
                      vlan: [
                        short: "-v",
                        help: "VLAN ID",
                        default: "VLAN to put the user into",
                        parser: :integer
                      ],
                      tunnel: [
                        short: "-t",
                        help: "TUNNEL_TYPE",
                        default: "ID of the tunnel type",
                        parser: :integer
                      ],
                      medium: [
                        short: "-m",
                        help: "TUNNEL_MEDIUM_TYPE",
                        default: "ID of the tunnel medium type",
                        parser: :integer
                      ]
                    ] ++ @site
                ]
              ]
            ]
          ]
        ],
        events: [
          name: "events",
          description: "list events",
          options: @site
        ],
        alerts: [
          name: "alerts",
          description: "list alerts",
          options: @site
        ]
      ]
    ]
  end
end
