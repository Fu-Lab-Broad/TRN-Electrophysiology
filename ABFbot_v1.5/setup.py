# from cx_Freeze import setup, Executable 
# import pkg_resources

from setuptools import setup

build_exe_options = {
    'excludes': [
        'jupyter',
        'ipython',
        'test',
        'html',
        'http'
    ]
}

setup(
    name='ABFbot',
    version='1.5',
    description='Automated Burst Detection',
    author='Lei Wang',
    author_email='wangl@broadinstitute.org',
    
    install_requires=[
        'numpy',
        'pandas',
        'matplotlib',
        'pyabf',
        'pyqt5'
    ]
    
    # options = {
        # "build_exe": 'excludes': [
            # 'jupyter',
            # 'ipython',
            # 'test',
            # 'html',
            # 'http'
        # ]
    # },
    # executables = [Executable("ABFbot.py")]
)
