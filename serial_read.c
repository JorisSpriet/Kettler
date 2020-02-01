#include <stdio.h>
#include <stdlib.h>
#include <windows.h>

// To cross-compile on Ubuntu:
//   sudo apt-get install mingw32 mingw32-binutils mingw32-runtime
//   i586-mingw32msvc-gcc -s -O3 -Wall -o serial_read.exe serial_read.c

const char *begin_string="10 second speed test begins";
const char *end_string="done!\r\n";
#define END_LEN 7

int main(int argc, char **argv)
{
	char buf[16384];
	HANDLE port;
	COMMTIMEOUTS timeout;
	COMMCONFIG cfg;
	BOOL ret;
	DWORD n, sum=0;

	if (argc < 2) {
		fprintf(stderr, "Usage:   serial_read.exe <port>\n");
		fprintf(stderr, "Example: serial_read.exe COM3:\n");
		return 1;
	}

	// TODO: check if the user typed "COM##" where the number is
	// greater than 9.  If so, automatically reformat to \\.\COM##

	// Open the serial port
	port = CreateFile(argv[1], GENERIC_READ | GENERIC_WRITE,
		0, 0, OPEN_EXISTING, 0, NULL);
	if (port == INVALID_HANDLE_VALUE) {
		fprintf(stderr, "Unable to open %s\n", argv[1]);
		return 1;
	}

	// Configure the port
	GetCommConfig(port, &cfg, &n);
	cfg.dcb.BaudRate = 115200;
	cfg.dcb.fBinary = TRUE;
	cfg.dcb.fParity = FALSE;
	cfg.dcb.fOutxCtsFlow = FALSE;
	cfg.dcb.fOutxDsrFlow = FALSE;
	cfg.dcb.fDtrControl = DTR_CONTROL_ENABLE;
	cfg.dcb.fDsrSensitivity = FALSE;
	cfg.dcb.fTXContinueOnXoff = TRUE;
	cfg.dcb.fOutX = FALSE;
	cfg.dcb.fInX = FALSE;
	cfg.dcb.fErrorChar = FALSE;
	cfg.dcb.fNull = FALSE;
	cfg.dcb.fRtsControl = RTS_CONTROL_ENABLE;
	cfg.dcb.fAbortOnError = FALSE;
	cfg.dcb.XonLim = 0x8000;
	cfg.dcb.XoffLim = 20;
	cfg.dcb.ByteSize = 8;
	cfg.dcb.Parity = NOPARITY;
	cfg.dcb.StopBits = ONESTOPBIT;
	SetCommConfig(port, &cfg, n);
	GetCommTimeouts(port, &timeout);
	timeout.ReadIntervalTimeout = 250;
	timeout.ReadTotalTimeoutMultiplier = 1;
	timeout.ReadTotalTimeoutConstant = 500;
	timeout.WriteTotalTimeoutConstant = 2500;
	timeout.WriteTotalTimeoutMultiplier = 1;
	SetCommTimeouts(port, &timeout);

	// Read data until we get a timeout or error or see the end string
	printf("Reading from %s\n", argv[1]);
	while (1) {
		ret = ReadFile(port, buf, sizeof(buf), &n, NULL);
		if (!ret) {
			fprintf(stderr, "Error reading from %s\n", argv[1]);
			break;
		}
		if (n < 1) {
			fprintf(stderr, "timeout reading from %s\n", argv[1]);
			break;
		}
		if (n < 50 && memcmp(buf, begin_string, strlen(begin_string)) == 0) {
			printf("read: %ld (begin string)\n", n);
			continue;
		}
		if (n < sizeof(buf) && n >= END_LEN &&
		  memcmp(buf + n - END_LEN, end_string, END_LEN) == 0) {
			printf("(end string)\n");
			sum += n - END_LEN;
			break;
		}
		sum += n;
		//printf("read: %ld, total: %ld\n", n, sum);
		printf(".");
		fflush(stdout);
	}

	CloseHandle(port);
	printf("Total bytes read: %ld\n", sum);
	printf("Speed %.2f kbytes/sec\n", sum / 10000.0);
	return 0;
}


