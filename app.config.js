// Expo app config. Values that differ per build environment come from
// EXPO_PUBLIC_* env vars so a fresh clone runs without editing this file.
module.exports = {
  expo: {
    name: "Team Roping",
    slug: "teamrope",
    scheme: "teamrope",
    version: '0.1.0',
    orientation: 'portrait',
    userInterfaceStyle: 'dark',
    newArchEnabled: true,
    splash: {
      resizeMode: 'contain',
      backgroundColor: "#150e09",
    },
    ios: {
      supportsTablet: true,
      bundleIdentifier: "pro.teamrope.app",
      infoPlist: {
        NSCameraUsageDescription: 'Record your runs so TeamRope can analyse them.',
        NSMicrophoneUsageDescription: 'Capture audio alongside your run video.',
        NSPhotoLibraryUsageDescription: 'Pick a run video to analyse.',
      },
    },
    android: {
      package: "pro.teamrope.app",
      adaptiveIcon: {
        backgroundColor: "#150e09",
      },
      edgeToEdgeEnabled: true,
    },
    web: { bundler: 'metro', output: 'static' },
    plugins: ['expo-router', 'expo-video'],
    experiments: { typedRoutes: true },
    extra: {
      eas: {
        projectId: "29d91d8f-50e2-4bd4-9026-1f4b2841fb45"
      },
      domain: "teamrope.pro",
      eventType: "teamroping",
    },
  },
};
