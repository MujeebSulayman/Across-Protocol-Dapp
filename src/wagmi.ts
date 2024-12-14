import { getDefaultConfig } from "@rainbow-me/rainbowkit";
import {
  arbitrum,
  base,
  mainnet,
  optimism,
  polygon,
  sepolia,
} from "wagmi/chains";

export const config = getDefaultConfig({
  appName: "HemSwap",
  projectId: "process.env.NEXT_PUBLIC_PROJECT_ID",
  chains: [mainnet, polygon, sepolia],
  ssr: true,
});


