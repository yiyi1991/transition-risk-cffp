from setuptools import setup, find_packages

# Read the requirements from the requirements.txt
with open("requirements.txt") as f:
    install_requires = f.read().splitlines()

setup(
    name="transition-risk-cffp",
    version="0.1",
    packages=find_packages(),
    install_requires=install_requires,
    include_package_data=True,
    author="JU Yiyi",
    author_email="juyiyi@iiasa.ac.at",
)
