by Mark Geurts <mark.w.geurts@gmail.com>
<br>Copyright &copy; 2016, University of Wisconsin Board of Regents

## Description

The Mobius3D Anonymized DICOM Database Tool captures plan data from a Mobius3D server, downloading an storing the anonymized DICOM data (CT, RTSTRUCT, RTPLAN, and RTDOSE) in a folder. The non-anonymized plan data is stored in a SQLite3 table and is displayed in a graphical user interface. The interface allows for plans to be searched, sorted, and exported for research and academic purposes.

Mobius3D is a product of [Mobius Medical Systems](http://www.mobiusmed.com/mobius3d/).

## Installation

This application can be installed as a MATLAB App or by cloning this git repository.  See [Installation and Use](../../wiki/Installation-and-Use) for more details.

## Usage and Documentation

This tool utilizes the Image Processing and Database MATLAB Toolboxes. To run the graphical interface, execute `DatabaseUI`. Alternatively, the functions `LoadDatabase()`, `ImportData()`, and `QueryDatabase()` functions can be used outside of the graphical interface. Please see the [wiki](../../wiki) for more information.

## License

Released under the GNU GPL v3.0 License.  See the [license](license) file for further details.