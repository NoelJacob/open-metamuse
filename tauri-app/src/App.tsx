import { defineTheme } from "@astryxdesign/core";
import { neutralTheme } from "@astryxdesign/theme-neutral";
import MuseApp from "./muse";
import "@astryxdesign/core/reset.css";
import "@astryxdesign/core/astryx.css";
// Muse primary sampled from the original Aura APK (colors.xml #ff5890ff, landing logo #BCD9F8 on white).
const museBlue = '#5890FF';

// Light theme tokens matching Flutter museLightTheme
const lightTokens: Record<string, string> = {
  '--astryx-color-primary': museBlue,
  '--astryx-color-on-primary': '#FFFFFF',
  '--astryx-color-primary-container': '#E8F0FE',
  '--astryx-color-on-primary-container': '#003D82',

  '--astryx-color-secondary': '#6C757D',
  '--astryx-color-on-secondary': '#FFFFFF',
  '--astryx-color-secondary-container': '#E2E8F0',

  '--astryx-color-tertiary': '#737373',
  '--astryx-color-tertiary-container': '#DFDFDF',
  '--astryx-color-on-tertiary': '#000000',

  '--astryx-color-background': '#F9FBFC',
  '--astryx-color-on-background': '#1A1A1A',

  '--astryx-color-surface': '#FFFFFF',
  '--astryx-color-surface-container-highest': '#F8F9FA',
  '--astryx-color-surface-container': '#FAFAFA',
  '--astryx-color-on-surface': '#1A1A1A',
  '--astryx-color-on-surface-variant': '#6F7278',
  '--astryx-color-surface-variant': '#E5E6E8',

  '--astryx-color-error': '#B00020',
  '--astryx-color-on-error': '#FFFFFF',
  '--astryx-color-success': '#27AE60',
  '--astryx-color-on-success': '#FFFFFF',
  '--astryx-color-warning': '#E67E22',
  '--astryx-color-on-warning': '#000000',

  '--astryx-font-family': "'Optimistic', system-ui, -apple-system, sans-serif",
  '--astryx-font-size': '16px',
  '--astryx-font-weight-normal': '400',
  '--astryx-font-weight-bold': '700',

  '--astryx-spacing-4': '0.25rem',
  '--astryx-spacing-8': '0.5rem',
  '--astryx-spacing-12': '0.75rem',
  '--astryx-spacing-16': '1rem',
  '--astryx-spacing-20': '1.25rem',
  '--astryx-spacing-24': '1.5rem',
  '--astryx-spacing-32': '2rem',

  '--astryx-radius-sm': '0.125rem',
  '--astryx-radius-md': '0.25rem',
  '--astryx-radius-lg': '0.5rem',
  '--astryx-radius-xl': '1rem',

  '--astryx-shadow-sm': '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
  '--astryx-shadow-md': '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
  '--astryx-shadow-lg': '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)',

  '--astryx-opacity-10': '0.1',
  '--astryx-opacity-20': '0.2',
  '--astryx-opacity-30': '0.3',
  '--astryx-opacity-50': '0.5',
};

// Dark theme tokens matching Flutter museDarkTheme
const darkTokens: Record<string, string> = {
  '--astryx-color-primary': museBlue,
  '--astryx-color-on-primary': '#FFFFFF',
  '--astryx-color-primary-container': '#003D82',
  '--astryx-color-on-primary-container': '#E8F0FE',

  '--astryx-color-secondary': '#A0AEC0',
  '--astryx-color-on-secondary': '#000000',
  '--astryx-color-secondary-container': '#1E242D',

  '--astryx-color-tertiary': '#737373',
  '--astryx-color-tertiary-container': '#3A3A3A',
  '--astryx-color-on-tertiary': '#000000',

  '--astryx-color-background': '#1A1A1A',
  '--astryx-color-on-background': '#F5F5F5',

  '--astryx-color-surface': '#2A2A2A',
  '--astryx-color-surface-container-highest': '#1F1F1F',
  '--astryx-color-surface-container': '#1E1E1E',
  '--astryx-color-on-surface': '#F5F5F5',
  '--astryx-color-on-surface-variant': '#6F7278',
  '--astryx-color-surface-variant': '#3A3A3A',

  '--astryx-color-error': '#E74C3C',
  '--astryx-color-on-error': '#FFFFFF',
  '--astryx-color-success': '#2ECC71',
  '--astryx-color-on-success': '#FFFFFF',
  '--astryx-color-warning': '#F1C40F',
  '--astryx-color-on-warning': '#000000',

  '--astryx-font-family': "'Optimistic', system-ui, -apple-system, sans-serif",
  '--astryx-font-size': '16px',
  '--astryx-font-weight-normal': '400',
  '--astryx-font-weight-bold': '700',

  '--astryx-spacing-4': '0.25rem',
  '--astryx-spacing-8': '0.5rem',
  '--astryx-spacing-12': '0.75rem',
  '--astryx-spacing-16': '1rem',
  '--astryx-spacing-20': '1.25rem',
  '--astryx-spacing-24': '1.5rem',
  '--astryx-spacing-32': '2rem',

  '--astryx-radius-sm': '0.125rem',
  '--astryx-radius-md': '0.25rem',
  '--astryx-radius-lg': '0.5rem',
  '--astryx-radius-xl': '1rem',

  '--astryx-shadow-sm': '0 1px 2px 0 rgba(0, 0, 0, 0.3)',
  '--astryx-shadow-md': '0 4px 6px -1px rgba(0, 0, 0, 0.4), 0 2px 4px -1px rgba(0, 0, 0, 0.3)',
  '--astryx-shadow-lg': '0 10px 15px -3px rgba(0, 0, 0, 0.4), 0 4px 6px -2px rgba(0, 0, 0, 0.3)',

  '--astryx-opacity-10': '0.1',
  '--astryx-opacity-20': '0.2',
  '--astryx-opacity-30': '0.3',
  '--astryx-opacity-50': '0.5',
};

// Define the custom Muse theme per official Theme docs: light/dark as token
// tuples (light first, dark second) so mode="light" renders the light chat.
const tupleTokens = Object.fromEntries(
  Object.keys(lightTokens).map((k) => [k, [lightTokens[k], darkTokens[k] ?? lightTokens[k]]]),
);
export const museTheme = defineTheme({
  ...neutralTheme,
  tokens: tupleTokens,
});

function App() {
  return <MuseApp theme={museTheme} />;
}

export default App;