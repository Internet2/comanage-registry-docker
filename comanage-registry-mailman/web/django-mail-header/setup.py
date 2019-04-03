import setuptools

setuptools.setup(
    name="django-mail-header",
    version="1.0.0",
    author="Scott Koranda",
    author_email="skoranda@gmail.com",
    description="Custom HTTP_MAIL header for Django authentication",
    packages=setuptools.find_packages('src'),
    package_dir={'': 'src'},
    classifiers=[
        "Programming Language :: Python :: 3",
        "Operating System :: OS Independent",
    ],
)
