// src/app/layout.tsx
import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'
import { ThemeProvider } from '@/components/theme-provider'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'Tranzo',
  description: 'Translate your documents into multiple languages',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <head>
        <link rel="icon" href="https://media.istockphoto.com/id/1279365501/vector/letter-t-logo-lettermark-monogram-typeface-type-emblem-character-trademark.jpg?s=612x612&w=0&k=20&c=zKgTOCrgmI7oiclozkfXURloWyH-W4lSZm8pz7LUsjg=" type="image/x-icon" />
      </head>
      <body className={inter.className}>
        <ThemeProvider attribute="class" defaultTheme="system" enableSystem disableTransitionOnChange>
          {children}
        </ThemeProvider>
      </body>
    </html>
  )
}