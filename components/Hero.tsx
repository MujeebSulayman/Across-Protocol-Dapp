import React, { useRef, useState } from 'react'
import { motion, useTransform, useScroll } from 'framer-motion'
import { FaRocket, FaNetworkWired, FaShieldAlt } from 'react-icons/fa'
import Link from 'next/link'

const HeroFeature: React.FC<{ 
  icon: React.ReactNode, 
  title: string, 
  description: string 
}> = ({ icon, title, description }) => (
  <motion.div 
    className="bg-white/10 backdrop-blur-md rounded-xl p-6 border border-white/10 transform transition-all duration-300 hover:scale-105 hover:shadow-2xl"
    whileHover={{ scale: 1.05 }}
    whileTap={{ scale: 0.95 }}
  >
    <div className="text-4xl text-primary-500 mb-4">{icon}</div>
    <h3 className="text-xl font-bold mb-2 text-white">{title}</h3>
    <p className="text-gray-300">{description}</p>
  </motion.div>
)

const Hero: React.FC = () => {
  const ref = useRef(null)
  const [mousePosition, setMousePosition] = useState({ x: 0, y: 0 })

  const handleMouseMove = (e: React.MouseEvent) => {
    const rect = e.currentTarget.getBoundingClientRect()
    setMousePosition({
      x: e.clientX - rect.left,
      y: e.clientY - rect.top
    })
  }

  return (
    <div 
      ref={ref}
      onMouseMove={handleMouseMove}
      className="relative min-h-screen w-full overflow-hidden bg-gradient-to-br from-[#0F172A] via-[#1E293B] to-[#0F172A] flex items-center justify-center"
    >
      {/* Animated Background Particles */}
      <div className="absolute inset-0 z-0 opacity-50">
        {[...Array(50)].map((_, i) => (
          <motion.div
            key={i}
            initial={{ 
              x: Math.random() * window.innerWidth, 
              y: Math.random() * window.innerHeight,
              opacity: 0 
            }}
            animate={{ 
              x: [
                Math.random() * window.innerWidth, 
                Math.random() * window.innerWidth, 
                Math.random() * window.innerWidth
              ],
              y: [
                Math.random() * window.innerHeight,
                Math.random() * window.innerHeight,
                Math.random() * window.innerHeight
              ],
              opacity: [0, 1, 0]
            }}
            transition={{
              duration: Math.random() * 10 + 5,
              repeat: Infinity,
              repeatType: "loop"
            }}
            className="absolute w-2 h-2 bg-white/20 rounded-full"
          />
        ))}
      </div>

      {/* Interactive Gradient Overlay */}
      <div 
        className="absolute inset-0 z-10 pointer-events-none"
        style={{
          background: `radial-gradient(
            circle at ${mousePosition.x}px ${mousePosition.y}px, 
            rgba(14, 165, 233, 0.2) 0%, 
            transparent 50%
          )`
        }}
      />

      {/* Main Content */}
      <div className="relative z-20 max-w-7xl mx-auto px-4 grid md:grid-cols-2 gap-12 items-center">
        {/* Text Section */}
        <motion.div 
          initial={{ opacity: 0, x: -50 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.8 }}
          className="text-white space-y-6"
        >
          <motion.h1 
            initial={{ opacity: 0, y: 50 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="text-5xl md:text-6xl font-extrabold tracking-tight"
          >
            Unleash the Power of <br />
            <span className="text-primary-400">Seamless Cross-Chain</span> Transfers
          </motion.h1>

          <motion.p
            initial={{ opacity: 0, y: 50 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.4 }}
            className="text-xl text-gray-300"
          >
            Transform your blockchain experience with lightning-fast, secure asset bridging across multiple networks.
          </motion.p>

          <motion.div
            initial={{ opacity: 0, y: 50 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.6 }}
            className="flex space-x-4"
          >
            <Link 
              href="/app" 
              className="bg-primary-600 text-white px-8 py-4 rounded-full font-bold hover:bg-primary-700 transition-all transform hover:scale-105 hover:shadow-xl flex items-center space-x-2"
            >
              <FaRocket />
              <span>Launch App</span>
            </Link>
            <Link 
              href="/docs" 
              className="border border-white/20 text-white px-8 py-4 rounded-full font-bold hover:bg-white/10 transition-all transform hover:scale-105 flex items-center space-x-2"
            >
              <FaNetworkWired />
              <span>Learn More</span>
            </Link>
          </motion.div>
        </motion.div>

        {/* Features Grid */}
        <motion.div 
          initial={{ opacity: 0, x: 50 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.8 }}
          className="grid grid-cols-1 md:grid-cols-2 gap-6"
        >
          <HeroFeature 
            icon={<FaNetworkWired />}
            title="Multi-Chain"
            description="Connect and transfer assets across diverse blockchain networks effortlessly."
          />
          <HeroFeature 
            icon={<FaShieldAlt />}
            title="Secure"
            description="Advanced security protocols ensure your assets are protected throughout transfer."
          />
          <HeroFeature 
            icon={<FaRocket />}
            title="Fast"
            description="Minimal latency and optimized routing for near-instantaneous transfers."
          />
          <HeroFeature 
            icon={<FaNetworkWired />}
            title="Interoperable"
            description="Break down blockchain silos with our universal bridging technology."
          />
        </motion.div>
      </div>
    </div>
  )
}
export default Hero