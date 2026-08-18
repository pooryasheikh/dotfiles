export default {
  defaultBrowser: {
    name: "Brave Browser",
    profile: "Default", // Common
  },

  handlers: [
    // QIC work domains → QIC profile (any opener)
    {
      match: [
        "qicbizdev.atlassian.net/*",
        "*.qic-int.online/*",
        "*.qic-dev.online/*",
        "*.qic-uat.online/*",
        "*.qic.online/*",
      ],
      browser: {
        name: "Brave Browser",
        profile: "Profile 1", // QIC
      },
    },

    // gcloud auth login → QIC profile (matched by Google Cloud SDK client ID in OAuth URL)
    {
      match: ({ url }) =>
        url.host === "accounts.google.com" && url.search.includes("32555940559"),
      browser: {
        name: "Brave Browser",
        profile: "Profile 1", // QIC
      },
    },

    // Any link from Slack → QIC profile
    {
      match: ({ opener }) => opener.name === "Slack",
      browser: {
        name: "Brave Browser",
        profile: "Profile 1", // QIC
      },
    },
  ],
};
