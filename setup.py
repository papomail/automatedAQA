from setuptools import setup, find_packages

setup(
    name='automatedAQA',
    version='0.9',
    description='Automated Annual QA is a set of scripts aimed to eliminate the repetitive manual labour and to improve the reproducibility of the Quality Control data analysis for MRI scanners',
    author='Patxi Torrealdea ',
    author_email='francisco.torrealdea@nhs.net',
    url='https://github.com/papomail/Annual_QA_pipeline',
    packages=find_packages(),

    install_requires=[
        
        "easygui_qt",
		"pathlib",
		"pydicom",
		"pandas",
		"openpyxl",
        "PyQt5"
  
    ],
    setup_requires=['pytest-runner', 'flake8'],
    tests_require=['pytest'],
    # package_dir={'automatedAQA':'automatedAQA'},
    package_data={
        'automatedAQA.MagNET_QA_scripts':['*.ijm'],
        'automatedAQA':['*.ijm', 'ijm_template_header','ijm_template_footer'],
 
    },
    include_package_data=True,
    entry_points={
        'console_scripts': ['aaqa=automatedAQA.automated_AQA:main']
    }    

)


