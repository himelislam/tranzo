"use client"

import { useState, type ChangeEvent, type FormEvent } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Input } from "@/components/ui/input"
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Progress } from "@/components/ui/progress"
import { Separator } from "@/components/ui/separator"
import {
  AlertCircle,
  CheckCircle,
  Upload,
  Download,
  FileText,
  Languages,
  RefreshCw,
  Loader2,
  Globe,
  ArrowRight,
} from "lucide-react"
import { Badge } from "@/components/ui/badge"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { ThemeToggle } from "../components/theme-toogle"

// Language data with TypeScript interface
interface Language {
  code: string
  name: string
}

const languages: Language[] = [
  { code: "en", name: "English" },
  { code: "sq", name: "Albanian" },
  { code: "ar", name: "Arabic" },
  { code: "az", name: "Azerbaijani" },
  { code: "eu", name: "Basque" },
  { code: "bn", name: "Bengali" },
  { code: "bg", name: "Bulgarian" },
  { code: "ca", name: "Catalan" },
  { code: "zh", name: "Chinese" },
  { code: "zt", name: "Chinese (traditional)" },
  { code: "cs", name: "Czech" },
  { code: "da", name: "Danish" },
  { code: "nl", name: "Dutch" },
  { code: "eo", name: "Esperanto" },
  { code: "et", name: "Estonian" },
  { code: "fi", name: "Finnish" },
  { code: "fr", name: "French" },
  { code: "gl", name: "Galician" },
  { code: "de", name: "German" },
  { code: "el", name: "Greek" },
  { code: "he", name: "Hebrew" },
  { code: "hi", name: "Hindi" },
  { code: "hu", name: "Hungarian" },
  { code: "id", name: "Indonesian" },
  { code: "ga", name: "Irish" },
  { code: "it", name: "Italian" },
  { code: "ja", name: "Japanese" },
  { code: "ko", name: "Korean" },
  { code: "lv", name: "Latvian" },
  { code: "lt", name: "Lithuanian" },
  { code: "ms", name: "Malay" },
  { code: "nb", name: "Norwegian" },
  { code: "fa", name: "Persian" },
  { code: "pl", name: "Polish" },
  { code: "pt", name: "Portuguese" },
  { code: "ro", name: "Romanian" },
  { code: "ru", name: "Russian" },
  { code: "sk", name: "Slovak" },
  { code: "sl", name: "Slovenian" },
  { code: "es", name: "Spanish" },
  { code: "sv", name: "Swedish" },
  { code: "tl", name: "Tagalog" },
  { code: "th", name: "Thai" },
  { code: "tr", name: "Turkish" },
  { code: "uk", name: "Ukranian" },
  { code: "ur", name: "Urdu" },
].sort((a, b) => a.name.localeCompare(b.name))

// Define status response types
interface StatusResponse {
  status: string
  step?: string
  progress?: number
  totalFiles?: number
  current?: number
  translatedFile?: string
}

export default function FileTranslator() {
  const [file, setFile] = useState<File | null>(null)
  const [language, setLanguage] = useState<string>("")
  const [fileId, setFileId] = useState<string | null>(null)
  const [status, setStatus] = useState<string>("")
  const [error, setError] = useState<string>("")
  const [isUploading, setIsUploading] = useState<boolean>(false)
  const [progress, setProgress] = useState<number>(0)
  const [activeTab, setActiveTab] = useState<string>("upload")
  const [step, setStep] = useState<string>("")
  const [totalFiles, setTotalFiles] = useState<number>(0)
  const [currentFile, setCurrentFile] = useState<number>(0)

  // Handle file input change
  const handleFileChange = (e: ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      setFile(e.target.files[0])
    }
  }

  // Handle form submission
  const handleSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault()

    if (!file || !language) {
      setError("Please select both a file and a language")
      return
    }

    setIsUploading(true)
    setError("")
    setActiveTab("status")

    const formData = new FormData()
    formData.append("file", file)
    formData.append("language", language)

    try {
      // Simulate upload progress
      const progressInterval = setInterval(() => {
        setProgress((prev) => {
          const newProgress = prev + Math.random() * 10
          return newProgress >= 100 ? 100 : newProgress
        })
      }, 500)

      // Upload the file
      const uploadResponse = await fetch(`${process.env.NEXT_PUBLIC_PORT}/upload`, {
        method: "POST",
        body: formData,
      })

      clearInterval(progressInterval)
      setProgress(100)

      if (!uploadResponse.ok) {
        throw new Error(`Upload failed: ${uploadResponse.statusText}`)
      }

      const { fileId, status } = (await uploadResponse.json()) as { fileId: string; status: string }
      setFileId(fileId)
      setStatus(status)

      // Start checking status
      checkStatus(fileId)
    } catch (error) {
      setIsUploading(false)
      setProgress(0)
      setError(`Error: ${error instanceof Error ? error.message : "Unknown error"}`)
      console.error("Error:", error)
    }
  }

  // Check file processing status
  const checkStatus = async (id: string) => {
    try {
      const statusResponse = await fetch(`${process.env.NEXT_PUBLIC_PORT}/status/${id}`)

      if (!statusResponse.ok) {
        throw new Error(`Failed to check status: ${statusResponse.statusText}`)
      }

      const { status, step, progress, totalFiles, current } = (await statusResponse.json()) as StatusResponse
      setStatus(status)
      setStep(step || "")
      setProgress(progress || 0)
      setTotalFiles(totalFiles || 0)
      setCurrentFile(current || 0)

      if (status === "completed") {
        setIsUploading(false)
      } else {
        // Check again after 5 seconds
        setTimeout(() => checkStatus(id), 5000)
      }
    } catch (error) {
      setError(`Status check error: ${error instanceof Error ? error.message : "Unknown error"}`)
      setIsUploading(false)
    }
  }

  // Handle download
  const handleDownload = () => {
    if (fileId) {
      window.location.href = `${process.env.NEXT_PUBLIC_PORT}/download/${fileId}`
    }
  }

  // Reset form
  const resetForm = () => {
    setFile(null)
    setLanguage("")
    setFileId(null)
    setStatus("")
    setError("")
    setIsUploading(false)
    setProgress(0)
    setActiveTab("upload")
    setStep("")
    setTotalFiles(0)
    setCurrentFile(0)
  }

  // Get status badge
  const getStatusBadge = () => {
    if (status === "completed") {
      return (
        <Badge variant="secondary" className="ml-2">
          <CheckCircle className="mr-1 h-3 w-3" />
          Completed
        </Badge>
      )
    } else if (status === "processing") {
      return (
        <Badge
          variant="outline"
          className="ml-2 bg-amber-50 text-amber-700 border-amber-200 dark:bg-amber-950 dark:text-amber-200 dark:border-amber-800"
        >
          <Loader2 className="mr-1 h-3 w-3 animate-spin" />
          Processing
        </Badge>
      )
    } else if (status) {
      return (
        <Badge variant="outline" className="ml-2">
          {status}
        </Badge>
      )
    }
    return null
  }

  return (
    <div className="container max-w-xl mx-auto py-8 px-4">
      <Card className="w-full shadow-lg border-primary/10">
        <CardHeader className="pb-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <Globe className="h-6 w-6 text-primary" />
              <CardTitle className="text-2xl">Minsitry Vineyard</CardTitle>
            </div>
            {fileId && getStatusBadge()}
          </div>
          <CardDescription>Translate documents and files to multiple languages</CardDescription>
        </CardHeader>

        <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
          <div className="px-6">
            <TabsList className="grid w-full grid-cols-2">
              <TabsTrigger value="upload" disabled={isUploading}>
                <Upload className="mr-2 h-4 w-4" />
                Upload
              </TabsTrigger>
              <TabsTrigger value="status" disabled={!fileId}>
                <FileText className="mr-2 h-4 w-4" />
                Status
              </TabsTrigger>
            </TabsList>
          </div>

          <CardContent className="pt-6">
            <TabsContent value="upload" className="mt-0">
              <form onSubmit={handleSubmit} className="space-y-5">
                <div className="space-y-3">
                  <div className="flex items-center">
                    <FileText className="h-4 w-4 mr-2 text-muted-foreground" />
                    <h3 className="text-sm font-medium">Select File</h3>
                  </div>

                  <div className="border-2 border-dashed rounded-lg p-4 hover:bg-muted/50 transition-colors">
                    <Input
                      id="fileInput"
                      type="file"
                      accept=".txt,.docx,.pdf,.zip"
                      onChange={handleFileChange}
                      required
                      className="cursor-pointer"
                    />
                    {file && (
                      <div className="mt-2 text-sm">
                        <span className="font-medium">Selected:</span> {file.name} ({(file.size / 1024).toFixed(1)} KB)
                      </div>
                    )}
                  </div>

                  <p className="text-xs text-muted-foreground flex items-center">
                    <AlertCircle className="h-3 w-3 mr-1" />
                    Supported formats: .txt, .docx, .pdf, .zip
                  </p>
                </div>

                <div className="space-y-3">
                  <div className="flex items-center">
                    <Languages className="h-4 w-4 mr-2 text-muted-foreground" />
                    <h3 className="text-sm font-medium">Target Language</h3>
                  </div>

                  <Select value={language} onValueChange={setLanguage}>
                    <SelectTrigger id="languageSelect" className="w-full">
                      <SelectValue placeholder="Select language" />
                    </SelectTrigger>
                    <SelectContent className="max-h-[200px]">
                      {languages.map((lang) => (
                        <SelectItem key={lang.code} value={lang.code}>
                          {lang.name}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                {error && (
                  <Alert variant="destructive">
                    <AlertCircle className="h-4 w-4" />
                    <AlertTitle>Error</AlertTitle>
                    <AlertDescription>{error}</AlertDescription>
                  </Alert>
                )}

                <Button type="submit" className="w-full" disabled={isUploading || !file || !language}>
                  {isUploading ? (
                    <>
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                      Processing...
                    </>
                  ) : (
                    <>
                      <Upload className="mr-2 h-4 w-4" />
                      Upload & Translate
                    </>
                  )}
                </Button>
              </form>
            </TabsContent>

            <TabsContent value="status" className="mt-0 space-y-5">
              {fileId && (
                <>
                  <div className="space-y-3">
                    <div className="flex items-center justify-between">
                      <h3 className="text-sm font-medium flex items-center">
                        <FileText className="h-4 w-4 mr-2 text-muted-foreground" />
                        File Information
                      </h3>
                    </div>

                    <div className="rounded-md bg-muted/50 p-4 space-y-2">
                      <div>
                        <span className="text-xs text-muted-foreground">File Name</span>
                        <p className="text-sm font-medium">{file?.name}</p>
                      </div>

                      <div>
                        <span className="text-xs text-muted-foreground">Target Language</span>
                        <p className="text-sm font-medium">
                          {languages.find((lang) => lang.code === language)?.name || language}
                        </p>
                      </div>

                      <div>
                        <span className="text-xs text-muted-foreground">File ID</span>
                        <p className="font-mono text-xs truncate">{fileId}</p>
                      </div>
                    </div>
                  </div>

                  <div className="space-y-3">
                    <div className="flex items-center justify-between">
                      <h3 className="text-sm font-medium flex items-center">
                        <RefreshCw className="h-4 w-4 mr-2 text-muted-foreground" />
                        Translation Progress
                      </h3>
                      {getStatusBadge()}
                    </div>

                    <div className="space-y-2">
                      <div className="flex items-center justify-between text-sm">
                        <span>{step || (status === "completed" ? "Translation complete" : "Processing your file...")}</span>
                        <span>{Math.round(progress)}%</span>
                      </div>
                      <Progress value={progress} className="h-2" />
                    </div>

                    {totalFiles > 0 && (
                      <p className="text-xs text-muted-foreground italic">
                        Processing file {currentFile} of {totalFiles}
                      </p>
                    )}
                  </div>

                  {error && (
                    <Alert variant="destructive">
                      <AlertCircle className="h-4 w-4" />
                      <AlertTitle>Error</AlertTitle>
                      <AlertDescription>{error}</AlertDescription>
                    </Alert>
                  )}
                </>
              )}
            </TabsContent>
          </CardContent>

          <CardFooter className="flex flex-col space-y-3 pt-0">
            <Separator />

            <div className="w-full space-y-3">
              {status === "completed" && (
                <Button className="w-full" onClick={handleDownload}>
                  <Download className="mr-2 h-4 w-4" />
                  Download Translated File
                </Button>
              )}

              <Button variant={status === "completed" ? "outline" : "secondary"} className="w-full" onClick={resetForm}>
                <ArrowRight className="mr-2 h-4 w-4" />
                {status === "completed" ? "Start New Translation" : "Cancel & Start Over"}
              </Button>
            </div>
          </CardFooter>
        </Tabs>
      </Card>

      {/* Theme Toggle Button */}
      <ThemeToggle />
    </div>
  )
}
