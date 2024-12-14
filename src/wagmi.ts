import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { http } from 'viem';
import {
  arbitrum,
  base,
  mainnet,
  optimism,
  polygon,
  sepolia,
  goerli,
  hardhat,
} from 'wagmi/chains';

// Ensure you have set WALLETCONNECT_PROJECT_ID in your .env file
const projectId = process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || '';

export const config = getDefaultConfig({
  appName: 'Hemswap',
  projectId,
  chains: [
    mainnet,
    polygon,
    arbitrum,
    optimism,
    base,
    sepolia,
    goerli,
    hardhat,
  ],
  ssr: true,

  transports: {
    [mainnet.id]: http(),
    [polygon.id]: http(),
    [arbitrum.id]: http(),
    [optimism.id]: http(),
    [base.id]: http(),
    [sepolia.id]: http(),
    [goerli.id]: http(),
    [hardhat.id]: http(),
  },
});