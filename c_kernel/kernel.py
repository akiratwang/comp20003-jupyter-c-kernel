from ipykernel.kernelbase import Kernel
import subprocess
import tempfile
import os


class CKernel(Kernel):
    implementation = 'c_kernel'
    implementation_version = '1.0'
    language = 'c'
    language_version = 'C11'
    language_info = {'name': 'c',
                     'mimetype': 'text/plain',
                     'file_extension': 'c'}
    banner = "C kernel.\n" \
             "Uses gcc, compiles in C11, and creates source code files and executables in temporary folder.\n"

    def __init__(self, *args, **kwargs):
        super(CKernel, self).__init__(*args, **kwargs)
        self.files = []

    def cleanup_files(self):
        """Remove all the temporary files created by the kernel"""
        for file in self.files:
            os.remove(file)

    def new_temp_file(self, **kwargs):
        """Create a new temp file to be deleted when the kernel shuts down"""
        # We don't want the file to be deleted when closed, but only when the kernel stops
        kwargs['delete'] = False
        file = tempfile.NamedTemporaryFile(**kwargs)
        self.files.append(file.name)
        return file

    @staticmethod
    def execute_command(cmd):
        """Execute a command and returns the return code, stdout and stderr"""
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = p.communicate()
        return p.returncode, stdout, stderr

    @staticmethod
    def compile_with_gcc(source_filename, binary_filename):
        args = ['gcc', source_filename, '-std=c11', '-o', binary_filename]
        return CKernel.execute_command(args)

    def do_execute(self, code, silent, store_history=True,
                   user_expressions=None, allow_stdin=False):

        retcode, stdout, stderr = None, '', ''
        with self.new_temp_file(suffix='.c') as source_file:
            source_file.write(code)
            source_file.flush()
            with self.new_temp_file(suffix='.out') as binary_file:
                retcode, stdout, stderr = self.compile_with_gcc(source_file.name, binary_file.name)
                self.log.error(retcode)
                self.log.error(stdout)
                self.log.error(stderr)

        retcode, out, err = CKernel.execute_command([binary_file.name])
        stdout += out
        stderr += err
        self.log.error(retcode)
        self.log.error(out)
        self.log.error(err)

        if not silent:
            stream_content = {'name': 'stderr', 'text': stderr}
            self.send_response(self.iopub_socket, 'stream', stream_content)
            stream_content = {'name': 'stdout', 'text': stdout}
            self.send_response(self.iopub_socket, 'stream', stream_content)
        return {'status': 'ok', 'execution_count': self.execution_count, 'payload': [], 'user_expressions': {}}