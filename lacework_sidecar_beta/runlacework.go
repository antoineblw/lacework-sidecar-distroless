package main

import (
    "io"
    "io/ioutil"
    "os"
    "os/exec"
    "bufio"
    "log"
    "net/http"
    "time"
    "strings"
)

func testLacework() bool {
   resp, err := http.Get("https://api.lacework.net")
   var _ = resp
   if err != nil {
      return false;
   }
   return true;
}

func tail(vlog log.Logger, filename string, pref string) {
    f, err := os.Open(filename)
    if err != nil {
        panic(err)
    }
    defer f.Close()
    r := bufio.NewReader(f)
    info, err := f.Stat()
    if err != nil {
        panic(err)
    }
    oldSize := info.Size()
    for {
        for line, prefix, err := r.ReadLine(); err != io.EOF; line, prefix, err = r.ReadLine() {
            if prefix {
		    vlog.Printf("%s: %s", pref, string(line))
            } else {
		    vlog.Printf("%s: %s", pref, string(line))
            }
        }
        pos, err := f.Seek(0, io.SeekCurrent)
        if err != nil {
            panic(err)
        }
        for {
            time.Sleep(time.Second)
            newinfo, err := f.Stat()
            if err != nil {
                panic(err)
            }
            newSize := newinfo.Size()
            if newSize != oldSize {
                if newSize < oldSize {
                    f.Seek(0, 0)
                } else {
                    f.Seek(pos, io.SeekStart)
                }
                r = bufio.NewReader(f)
                oldSize = newSize
                break
            }
        }
    }
}

func dataCollectorPipe(vlog log.Logger, pipe io.Reader, name string) {
    in := bufio.NewScanner(pipe)
    for in.Scan() {
          vlog.Printf("%s: %s", name, in.Text())
    }
}

func fileCopy(src string, dst string) {

    bytesRead, err := ioutil.ReadFile(src)

    if err != nil {
        log.Fatal(err)
    }

    err = ioutil.WriteFile(dst, bytesRead, 0777)

    if err != nil {
        log.Fatal(err)
    }
}

func execDataCollector(vlog log.Logger, verbose string) {
    vlog.Print("Launching Lacework datacollector")

    // The datacollector must be run from /var/lib/lacework/
    err := os.Mkdir("/var/lib/lacework", 0755)
    if err != nil {
          vlog.Fatal(err)
    }
    files, err := os.ReadDir("/var/lib/lacework-backup")

    if err != nil {
          vlog.Fatal(err)
    }
    for _, file := range files {
	    if (file.IsDir()) {
		    vlog.Printf("Copying /var/lib/lacework-backup/%s/datacollector-musl", file.Name())
		    fileCopy("/var/lib/lacework-backup/"+file.Name()+"/datacollector-musl", "/var/lib/lacework/datacollector")
	    }
    }
    os.Mkdir("/lib", 0755)
    os.Symlink("/lacework/lib/ld-musl-x86_64.so.1", "/lib/ld-musl-x86_64.so.1")

    vlog.Printf("lacework setup complete, launching datacollector")
    cmd := exec.Command("/var/lib/lacework/datacollector")
    stdout, err := cmd.StdoutPipe()
    stderr, err := cmd.StderrPipe()

    if err != nil {
          vlog.Fatal(err)
    }

    if err := cmd.Start(); err != nil {
          vlog.Fatal(err)
    }
    go dataCollectorPipe(vlog, stdout, "lw stdout")
    go dataCollectorPipe(vlog, stderr, "lw stderr")

    if (verbose == "true") {
	    // Now we open a pipe to the datacollector, but we wait in case it has not been created yet...
	    time.Sleep(5 * time.Second)
	    go tail(vlog, "/var/log/lacework/datacollector.log", "lw data")
    }

    // Now we just loop forever, don't want to exit the go func...
    for {
       time.Sleep(5 * time.Second)
    }
}

func execMonitoredProcess(val string, vlog log.Logger) {
    vlog.Printf("Launching RUN_CMD Process %s", val)

    // Parse the RUN_CMD into a command vs. args.
    s := strings.Split(val, " ")

    cmd := exec.Command(s[0], s[1:]...)

    stdout, err := cmd.StdoutPipe()

    if err != nil {
          vlog.Fatal(err)
    }

    if err := cmd.Start(); err != nil {
          vlog.Fatal(err)
    }

    in := bufio.NewScanner(stdout)

    // Now we just loop forever, redirect app stdout to our log/stdout
    for {
       for in.Scan() {
         vlog.Printf(in.Text())
       }

       time.Sleep(1 * time.Second)
    }
}

func main() {
   logger := log.New(os.Stdout, "", 0)
   // If RUN_CMD is not defined we don't run. This is the default case and what happens when we're run
   // in fargate is that we just terminate.
   verbose, ok := os.LookupEnv("LaceworkVerbose")
   if (ok && (verbose == "true")) {
     logger.Printf("Verbose logs enabled")
     env_vars := os.Environ()
     for _, ele := range env_vars { 
	logger.Printf("  ENV %s", ele)
     }
   }
   
   val, ok := os.LookupEnv("RUN_CMD")
   if (!ok) {
     logger.Printf("No RUN_CMD defined, exit")
     return;
   }


   logger.Printf("Loading Lacework")
   // Parameters

   // Test connectivity to lacework.
   if (!testLacework()) {
     logger.Printf("Connectivity to Lacework problem - exiting")
     return;
   }

   // Launch Lacework datacollector
   go execDataCollector(*logger, verbose)
       
   
   //Give lacework a few seconds to launch so that we can get all the telemetry of boot
   time.Sleep(2 * time.Second)

   // RUN_CMD env parm will be what we spawn last.
   go execMonitoredProcess(val, *logger)

   for {
	   //Do nothing here, in theory should wait and monitor health of sub processes.
	  time.Sleep(8 * time.Second)
   }
}
