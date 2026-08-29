/** @type {import('next').NextConfig} */
const nextConfig = {
  // Fijar la raíz del workspace al directorio actual (path de drive, no UNC)
  // Necesario cuando el proyecto está en un share de red Windows (\\server\share → Z:\)
  // Esto evita que Turbopack y webpack mezclen paths UNC con forward-slashes
  turbopack: {
    root: __dirname,
  },

  // Habilitar optimización de imágenes
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '*.supabase.co',
        pathname: '/storage/v1/object/public/**',
      },
    ],
  },

  // Fix de webpack para resolución en shares de red Windows
  // Evita que symlinks mezclen paths UNC (//server/share) con Z:\
  webpack: (config) => {
    config.resolve.symlinks = false;
    return config;
  },

  // Headers de seguridad
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'X-Frame-Options',
            value: 'DENY',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin',
          },
          {
            key: 'X-XSS-Protection',
            value: '1; mode=block',
          },
        ],
      },
    ];
  },
};

module.exports = nextConfig;
