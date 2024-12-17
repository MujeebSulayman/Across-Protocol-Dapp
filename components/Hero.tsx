import React from 'react';
import Image from 'next/image';
import Link from 'next/link';

const Hero: React.FC = () => {
  return (
    <div className="relative min-h-screen flex items-center justify-center overflow-hidden bg-gradient-to-br from-blue-50 to-blue-100 py-16 px-4 sm:px-6 lg:px-8">
      {/* Animated Background Elements */}
      <div className="absolute inset-0 pointer-events-none">
        {/* Floating Crypto Shapes */}
        <div className="absolute top-10 left-10 w-32 h-32 bg-blue-300/30 rounded-full animate-float"></div>
        <div className="absolute bottom-20 right-20 w-48 h-48 bg-purple-300/30 rounded-full animate-float-slow"></div>
        
        {/* Geometric Crypto Patterns */}
        <div className="absolute top-1/4 left-1/4 transform -translate-x-1/2 -translate-y-1/2 rotate-45 w-64 h-64 border-4 border-blue-200/20 rounded-3xl opacity-20"></div>
        <div className="absolute bottom-1/4 right-1/4 transform translate-x-1/2 translate-y-1/2 -rotate-45 w-80 h-80 border-4 border-purple-200/20 rounded-3xl opacity-20"></div>
        
        {/* Gradient Overlay */}
        <div className="absolute inset-0 bg-gradient-to-br from-blue-50/50 to-purple-100/50 mix-blend-overlay"></div>
      </div>

      {/* Content Container */}
      <div className="relative z-10 max-w-4xl mx-auto text-center">
        <div className="relative z-20">
          <h1 className="text-4xl md:text-6xl font-extrabold text-gray-900 mb-6 leading-tight">
            Hemswap: Revolutionizing 
            <br />
            Cross-Chain Token Exchanges
          </h1>
          
          <p className="text-xl md:text-2xl text-gray-600 mb-10 max-w-3xl mx-auto">
            Seamlessly swap tokens across multiple blockchains with minimal fees, 
            advanced security, and unparalleled interoperability. Your ultimate 
            cross-chain trading platform.
          </p>
          
          <div className="flex justify-center space-x-4">
            <Link href="/swap" className="px-8 py-3 bg-blue-600 text-white font-semibold rounded-lg hover:bg-blue-700 transition-colors shadow-md hover:shadow-lg">
              Launch Swap
            </Link>
            
            <Link href="/learn" className="px-8 py-3 bg-white text-blue-600 font-semibold rounded-lg border border-blue-600 hover:bg-blue-50 transition-colors shadow-md hover:shadow-lg">
              How It Works
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Hero;
