/*
 * Copyright 2020       Łukasz Wojniłowicz <lukasz.wojnilowicz@gmail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef STORAGE_SQL_SQLCIPHER_BACKEND_H
#define STORAGE_SQL_SQLCIPHER_BACKEND_H

// ----------------------------------------------------------------------------
// QT Includes

// ----------------------------------------------------------------------------
// KDE Includes

// ----------------------------------------------------------------------------
// Project Includes

#include "sqlite/backend.h"

class QSqlDatabase;
class QUrl;
class QString;

namespace Storage {
struct Issue;
namespace Sql {
namespace SQLCipher {

class Backend : public SQLite::Backend
{
public:
  Backend();
  ~Backend();

  bool unlockDatabase(const QUrl &url);
};

} // namespace SQLCipher
} // namespace Sql
} // namespace Storage

#endif
