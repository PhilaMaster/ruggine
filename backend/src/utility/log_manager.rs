pub mod log_manager{
    use sysinfo::System;
    use std::fs::OpenOptions;
    use std::io::Write;
    use std::time::Duration;
    use tokio::time;
    use std::fs;


    pub async fn log_cpu_usage() {
        let pid = std::process::id();
        let mut sys = System::new_all();
        //check if the logs directory exists, create it if not 
        if let Err(e) = fs::create_dir_all("logs") {
            eprintln!("Errore nella creazione della cartella logs: {}", e);
            return;
        }
        loop {
            time::sleep(Duration::from_secs(120)).await;
            sys.refresh_process(sysinfo::Pid::from_u32(pid));//refresh the process information

            if let Some(process) = sys.process(sysinfo::Pid::from_u32(pid)) {
                let cpu_usage = process.cpu_usage();
                let log_line = format!(
                    "Timestamp: {}, PID: {}, CPU Usage: {:.2}%\n",
                    chrono::Utc::now().format("%Y-%m-%d %H:%M:%S"),
                    pid,
                    cpu_usage
                );
                print!("Stampo log: {}", log_line);
                match OpenOptions::new()
                    .create(true)
                    .append(true)
                    .open("logs/server_cpu.log")
                {
                    Ok(mut file) => {
                        if let Err(e) = file.write_all(log_line.as_bytes()) {
                            eprintln!("Errore nella scrittura del file: {}", e);
                        } else {
                            //forzo flush
                            if let Err(e) = file.flush() {
                                eprintln!("Errore nel flush del file: {}", e);
                            }
                        }
                    }
                    Err(e) => {
                        eprintln!("Errore nell'apertura del file: {}", e);
                    }
                }
            }
        }
    }
}